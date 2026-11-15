import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../config/app_config.dart';
import '../network/dio_client.dart';
import '../push/push_arrived.dart';
import 'pusher_socket.dart';

/// Datos de conexión al servidor de sockets del entorno.
typedef RealtimeConfig = ({String host, int port, String key, bool tls});

/// Config del entorno, o `null` si no tiene tiempo real configurado. Seam para
/// tests.
final realtimeConfigProvider = Provider<RealtimeConfig?>((ref) {
  if (AppConfig.socketHost.isEmpty || AppConfig.socketKey.isEmpty) return null;
  return (
    host: AppConfig.socketHost,
    port: AppConfig.socketPort,
    key: AppConfig.socketKey,
    tls: AppConfig.socketTls,
  );
});

/// Cómo se abre el socket. Seam para tests.
final realtimeConnectorProvider = Provider<RealtimeSocketConnector>(
  (ref) => connectIoSocket,
);

/// Avisos EN TIEMPO REAL: escucha el canal privado del usuario
/// (`private-user.{id}`, evento `inbox.updated`) y avisa a las bandejas para
/// que se refresquen al instante, sin esperar al refresco por tiempo.
///
/// Vive mientras hay sesión y la app está EN PRIMER PLANO: en segundo plano se
/// desconecta (batería) y el aviso llega por push. Si el entorno no tiene
/// sockets (sin config, o el backend responde 503) no hace nada: sigue el
/// refresco de siempre. Se reconecta sola con espera creciente.
///
/// El estado es la cantidad de avisos sin leer que informó el último evento
/// (`null` si todavía no llegó ninguno).
class InboxRealtime extends Notifier<int?> {
  PusherChannelSession? _channel;
  StreamSubscription<RealtimeEvent>? _events;
  Timer? _retry;
  AppLifecycleListener? _lifecycle;
  int _attempt = 0;
  bool _disposed = false;

  /// El backend dijo que este entorno no tiene sockets: no se insiste.
  bool _unavailable = false;

  /// Evita dos conexiones a la vez.
  bool _connecting = false;

  @override
  int? build() {
    _disposed = false;
    _unavailable = false;
    // Otra sesión (o ninguna): se vuelve a armar todo.
    final session = ref.watch(
      sessionProvider.select((s) => (s?.token != null, s?.userId)),
    );
    final config = ref.watch(realtimeConfigProvider);
    ref.onDispose(_dispose);
    if (config == null || !session.$1) return null;
    try {
      _lifecycle = AppLifecycleListener(
        onResume: _connect,
        onPause: _disconnect,
      );
    } on FlutterError {
      // Sin binding (tests de Dart puro): no hay ciclo de vida que escuchar.
    }
    // Fuera del build: conectar cambia estado y hace red.
    scheduleMicrotask(_connect);
    return null;
  }

  void _dispose() {
    _disposed = true;
    _lifecycle?.dispose();
    _lifecycle = null;
    _disconnect();
  }

  void _disconnect() {
    _retry?.cancel();
    _retry = null;
    unawaited(_events?.cancel());
    _events = null;
    unawaited(_channel?.close());
    _channel = null;
  }

  /// Id del usuario: el de la sesión o, en una sesión guardada por una
  /// versión anterior, el que devuelve `/app/auth/me` (una sola vez).
  Future<int?> _userId() async {
    final known = ref.read(sessionProvider)?.userId;
    if (known != null) return known;
    try {
      final me = await ref.read(logisticsApiProvider).auth.appMe();
      ref
          .read(sessionProvider.notifier)
          .applyProfile(
            abilities: me.abilities,
            storeNode: me.user.node,
            userId: me.user.id,
          );
      return me.user.id;
    } on Object {
      return null;
    }
  }

  Future<String> _authorize(String socketId, String channel) async {
    final res = await ref
        .read(dioProvider)
        .post<Map<String, Object?>>(
          '/app/broadcasting/auth',
          data: {'socket_id': socketId, 'channel_name': channel},
        );
    final auth = res.data?['auth'];
    if (auth is! String) throw StateError('auth sin firma');
    return auth;
  }

  Future<void> _connect() async {
    if (_disposed || _unavailable || _connecting || _channel != null) return;
    final config = ref.read(realtimeConfigProvider);
    if (config == null) return;
    _connecting = true;
    _retry?.cancel();
    try {
      final userId = await _userId();
      if (_disposed || userId == null) return;
      final channel = await PusherChannelSession.open(
        uri: PusherChannelSession.endpoint(
          host: config.host,
          port: config.port,
          key: config.key,
          tls: config.tls,
        ),
        channel: 'private-user.$userId',
        authorize: _authorize,
        connect: ref.read(realtimeConnectorProvider),
      );
      if (_disposed) {
        await channel.close();
        return;
      }
      _channel = channel;
      _attempt = 0;
      _events = channel.events.listen(_onEvent);
      // Al conectar (o reconectar) pudo haberse perdido algo: refrescar.
      ref.read(pushArrivedProvider.notifier).bump();
      unawaited(channel.done.then((_) => _onClosed(channel)));
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 503 || status == 403 || status == 404) {
        // Entorno sin sockets (o canal no permitido): no se insiste.
        _unavailable = true;
      } else {
        _scheduleRetry();
      }
    } on Object {
      _scheduleRetry();
    } finally {
      _connecting = false;
    }
  }

  void _onEvent(RealtimeEvent event) {
    if (event.name != 'inbox.updated') return;
    final unread = event.data['unread'];
    if (unread is num) state = unread.toInt();
    ref.read(pushArrivedProvider.notifier).bump();
  }

  void _onClosed(PusherChannelSession channel) {
    if (_disposed || !identical(_channel, channel)) return;
    _channel = null;
    unawaited(_events?.cancel());
    _events = null;
    _scheduleRetry();
  }

  /// Reintento con espera creciente: 2 s, 4 s, 8 s… hasta 1 minuto.
  void _scheduleRetry() {
    if (_disposed || _unavailable) return;
    _retry?.cancel();
    final seconds = (2 << _attempt.clamp(0, 5)).clamp(2, 60);
    _attempt++;
    _retry = Timer(Duration(seconds: seconds), _connect);
  }
}

final inboxRealtimeProvider = NotifierProvider<InboxRealtime, int?>(
  InboxRealtime.new,
);
