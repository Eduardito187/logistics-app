import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../network/dio_client.dart';
import '../push/push_arrived.dart';
import 'pusher_socket.dart';
import 'realtime_bus.dart';

/// A dónde conectarse y qué canales tiene cada tema para este usuario.
typedef RealtimeEndpoint = ({Uri uri, Map<String, List<String>> channels});

/// Pide al backend la conexión; `null` = el entorno no tiene tiempo real.
typedef RealtimeEndpointLoader = Future<RealtimeEndpoint?> Function();

/// Conexión del entorno. La clave NO va fija en la app: la da
/// `GET /app/broadcasting/config`, y el socket se publica por el mismo host y
/// puerto que la API. Seam para tests.
final realtimeEndpointProvider = Provider<RealtimeEndpointLoader>((ref) {
  return () async {
    final dio = ref.read(dioProvider);
    final res = await dio.get<Map<String, Object?>>('/app/broadcasting/config');
    final data = res.data;
    final key = data?['key'];
    if (data?['enabled'] != true || key is! String || key.isEmpty) return null;
    final path = data?['path'];
    return (
      uri: PusherConnection.endpoint(
        api: Uri.parse(dio.options.baseUrl),
        key: key,
        path: path is String && path.isNotEmpty ? path : '/app',
      ),
      channels: _channelsFrom(data?['channels']),
    );
  };
});

/// `channels`: tema → canal o lista de canales.
Map<String, List<String>> _channelsFrom(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries)
      if (entry.key is String)
        entry.key as String: switch (entry.value) {
          final String one => [one],
          final List<Object?> many => [
            for (final item in many)
              if (item is String) item,
          ],
          _ => const <String>[],
        },
  };
}

/// Cómo se abre el socket. Seam para tests.
final realtimeConnectorProvider = Provider<RealtimeSocketConnector>(
  (ref) => connectIoSocket,
);

/// La conexión de TIEMPO REAL de la app: una sola, compartida por todo lo que
/// antes refrescaba por tiempo (avisos, notificaciones, flota, planes).
///
/// - Siempre escucha el tema del usuario; los demás temas, solo mientras una
///   pantalla los pide por el [RealtimeBus].
/// - Vive mientras hay sesión y la app está EN PRIMER PLANO: en segundo plano
///   se desconecta (batería) y lo urgente llega por push.
/// - Publica en [realtimeLiveProvider] qué temas llegan por socket; el resto
///   sigue con su refresco de respaldo. Si el entorno no tiene sockets
///   (`enabled: false`, 503/404) no insiste. Se reconecta sola con espera
///   creciente.
class RealtimeHub extends Notifier<void> {
  PusherConnection? _connection;
  StreamSubscription<RealtimeEvent>? _events;
  Timer? _retry;
  AppLifecycleListener? _lifecycle;
  void Function()? _stopUser;
  int _attempt = 0;
  bool _disposed = false;

  /// El backend dijo que este entorno no tiene sockets: no se insiste.
  bool _unavailable = false;

  /// Evita dos conexiones a la vez.
  bool _connecting = false;

  /// Conexión ya consultada (se pide una vez por sesión).
  RealtimeEndpoint? _endpoint;

  /// Temas suscritos en la conexión actual, con sus canales.
  final Map<String, List<String>> _joined = {};

  /// Se guarda en el build: al cerrar no se puede leer otro provider.
  late RealtimeBus _bus;

  @override
  void build() {
    _disposed = false;
    _unavailable = false;
    _endpoint = null;
    // Otra sesión (o ninguna): se vuelve a armar todo.
    final session = ref.watch(
      sessionProvider.select((s) => (s?.token != null, s?.userId)),
    );
    ref.onDispose(_dispose);
    final bus = _bus = ref.read(realtimeBusProvider);
    _stopUser = bus.listen(RealtimeTopic.user, _onUserEvent);
    bus.onDemand = _onDemand;
    if (session.$1) {
      try {
        _lifecycle = AppLifecycleListener(
          onResume: _connect,
          onPause: () {
            _disconnect();
            _syncLive();
          },
        );
      } on FlutterError {
        // Sin binding (tests de Dart puro): no hay ciclo de vida que escuchar.
      }
    }
    // Fuera del build: conectar cambia estado y hace red.
    scheduleMicrotask(() {
      if (_disposed) return;
      _syncLive();
      if (session.$1) unawaited(_connect());
    });
  }

  void _dispose() {
    _disposed = true;
    _lifecycle?.dispose();
    _lifecycle = null;
    _bus.onDemand = null;
    _stopUser?.call();
    _stopUser = null;
    _disconnect();
  }

  void _disconnect() {
    _retry?.cancel();
    _retry = null;
    unawaited(_events?.cancel());
    _events = null;
    unawaited(_connection?.close());
    _connection = null;
    _joined.clear();
  }

  /// Publica qué temas llegan por socket.
  void _syncLive() {
    if (_disposed) return;
    ref.read(realtimeLiveProvider.notifier).set(_joined.keys.toSet());
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

  /// Canales de [topic] para este usuario. Si el backend no los lista, el
  /// tema del usuario cae a su canal propio y los demás quedan sin socket.
  Future<List<String>> _channelsOf(String topic) async {
    final listed = _endpoint?.channels[topic];
    if (listed != null) return listed;
    if (topic != RealtimeTopic.user) return const [];
    final id = await _userId();
    return id == null ? const [] : ['private-user.$id'];
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
    if (_disposed || _unavailable || _connecting || _connection != null) return;
    _connecting = true;
    _retry?.cancel();
    try {
      final endpoint = _endpoint ??= await ref.read(realtimeEndpointProvider)();
      if (_disposed) return;
      if (endpoint == null) {
        // El backend dijo que este entorno no tiene tiempo real.
        _unavailable = true;
        return;
      }
      final connection = await PusherConnection.open(
        uri: endpoint.uri,
        authorize: _authorize,
        connect: ref.read(realtimeConnectorProvider),
      );
      if (_disposed) {
        await connection.close();
        return;
      }
      _connection = connection;
      _events = connection.events.listen(_onEvent);
      unawaited(connection.done.then((_) => _onClosed(connection)));
      // El canal del usuario es obligatorio: si no se puede, no hay conexión.
      await _join(RealtimeTopic.user, required: true);
      _attempt = 0;
      for (final topic in _bus.topics) {
        await _join(topic);
      }
    } on DioException catch (error) {
      _disconnect();
      _syncLive();
      final status = error.response?.statusCode;
      if (status == 503 || status == 403 || status == 404) {
        // Entorno sin sockets (o canal no permitido): no se insiste.
        _unavailable = true;
      } else {
        _scheduleRetry();
      }
    } on Object {
      _disconnect();
      _syncLive();
      _scheduleRetry();
    } finally {
      _connecting = false;
    }
  }

  /// Suscribe los canales de [topic]. Un tema opcional que falla (sin canales
  /// o sin permiso) queda sin socket y su pantalla sigue con el respaldo.
  Future<void> _join(String topic, {bool required = false}) async {
    final connection = _connection;
    if (connection == null || _joined.containsKey(topic)) return;
    final channels = await _channelsOf(topic);
    if (!identical(_connection, connection)) return;
    if (channels.isEmpty) {
      if (required) throw StateError('sin canal para $topic');
      return;
    }
    try {
      for (final channel in channels) {
        await connection.subscribe(channel);
      }
    } on Object {
      channels.forEach(connection.unsubscribe);
      if (required) rethrow;
      return;
    }
    if (_disposed || !identical(_connection, connection)) return;
    // Mientras se firmaba, la pantalla pudo irse.
    if (!_bus.topics.contains(topic)) {
      channels.forEach(connection.unsubscribe);
      return;
    }
    _joined[topic] = channels;
    _syncLive();
    // Al conectar (o reconectar) pudo haberse perdido algo: refrescar.
    if (topic == RealtimeTopic.user) {
      ref.read(pushArrivedProvider.notifier).bump();
    }
  }

  void _leave(String topic) {
    final channels = _joined.remove(topic);
    if (channels == null) return;
    channels.forEach(_connection?.unsubscribe ?? (_) {});
    // Puede llamarse desde el `dispose` de una pantalla: publicar después.
    scheduleMicrotask(_syncLive);
  }

  void _onDemand(String topic, bool wanted) {
    if (_disposed) return;
    if (wanted) {
      unawaited(_join(topic));
    } else {
      _leave(topic);
    }
  }

  void _onEvent(RealtimeEvent event) {
    for (final entry in _joined.entries.toList()) {
      if (entry.value.contains(event.channel)) {
        _bus.dispatch(entry.key, event);
      }
    }
  }

  /// Avisos y notificaciones: las bandejas se vuelven a pedir.
  void _onUserEvent(RealtimeEvent event) {
    if (_disposed) return;
    if (event.name == 'inbox.updated' ||
        event.name == 'notifications.updated') {
      ref.read(pushArrivedProvider.notifier).bump();
    }
  }

  void _onClosed(PusherConnection connection) {
    if (_disposed || !identical(_connection, connection)) return;
    _disconnect();
    _syncLive();
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

final realtimeHubProvider = NotifierProvider<RealtimeHub, void>(
  RealtimeHub.new,
);
