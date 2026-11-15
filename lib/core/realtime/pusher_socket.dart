import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Conexión mínima a un servidor de sockets con protocolo Pusher (Soketi).
///
/// Solo lo que la app necesita: conectarse, suscribirse a UN canal privado
/// (con la firma que da el backend) y recibir sus eventos. Sin dependencias:
/// usa el `WebSocket` de `dart:io`. La reconexión la decide quien la usa.
abstract class RealtimeSocket {
  Stream<Object?> get messages;
  void send(String data);
  Future<void> close();
}

/// Abre el socket real. Seam para tests.
typedef RealtimeSocketConnector = Future<RealtimeSocket> Function(Uri uri);

Future<RealtimeSocket> connectIoSocket(Uri uri) async {
  final socket = await WebSocket.connect(
    uri.toString(),
  ).timeout(const Duration(seconds: 15));
  // Latido de bajo nivel: detecta una conexión muerta (cambio de red).
  socket.pingInterval = const Duration(seconds: 30);
  return _IoSocket(socket);
}

class _IoSocket implements RealtimeSocket {
  _IoSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<Object?> get messages => _socket;

  @override
  void send(String data) => _socket.add(data);

  @override
  Future<void> close() => _socket.close();
}

/// Un evento recibido en el canal.
typedef RealtimeEvent = ({String name, Map<String, Object?> data});

/// Firma la suscripción a un canal privado (`"<key>:<firma>"`).
typedef ChannelAuthorizer =
    Future<String> Function(String socketId, String channel);

/// Sesión de un canal privado: conecta, se suscribe y entrega los eventos.
/// [done] se completa cuando la conexión se cae o se cierra.
class PusherChannelSession {
  PusherChannelSession._(this._socket, this._subscription, this._events);

  final RealtimeSocket _socket;
  final StreamSubscription<Object?> _subscription;
  final StreamController<RealtimeEvent> _events;

  Stream<RealtimeEvent> get events => _events.stream;

  /// Se completa cuando la conexión termina (caída o [close]).
  Future<void> get done => _events.done;

  Future<void> close() async {
    await _subscription.cancel();
    try {
      await _socket.close();
    } on Object {
      // Ya estaba cerrada.
    }
    if (!_events.isClosed) await _events.close();
  }

  /// URL de conexión del protocolo Pusher.
  static Uri endpoint({
    required String host,
    required int port,
    required String key,
    required bool tls,
  }) => Uri(
    scheme: tls ? 'wss' : 'ws',
    host: host,
    port: port,
    path: '/app/$key',
    queryParameters: const {
      'protocol': '7',
      'client': 'distrack',
      'version': '1.0',
    },
  );

  /// Conecta a [uri] y se suscribe a [channel]. Lanza si la conexión o la
  /// firma fallan (quien llama decide si reintenta).
  static Future<PusherChannelSession> open({
    required Uri uri,
    required String channel,
    required ChannelAuthorizer authorize,
    RealtimeSocketConnector connect = connectIoSocket,
  }) async {
    final socket = await connect(uri);
    final events = StreamController<RealtimeEvent>.broadcast();
    final ready = Completer<void>();

    Future<void> onMessage(Object? raw) async {
      if (raw is! String) return;
      final Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return;
      }
      if (decoded is! Map) return;
      final name = decoded['event'];
      if (name is! String) return;
      final data = _dataOf(decoded['data']);
      switch (name) {
        case 'pusher:connection_established':
          final socketId = data['socket_id'];
          if (socketId is! String) return;
          try {
            final auth = await authorize(socketId, channel);
            socket.send(
              jsonEncode({
                'event': 'pusher:subscribe',
                'data': {'auth': auth, 'channel': channel},
              }),
            );
          } on Object catch (error, stack) {
            if (!ready.isCompleted) ready.completeError(error, stack);
          }
        case 'pusher_internal:subscription_succeeded':
          if (!ready.isCompleted) ready.complete();
        case 'pusher:ping':
          socket.send(jsonEncode({'event': 'pusher:pong', 'data': {}}));
        case 'pusher:error':
          if (!ready.isCompleted) {
            ready.completeError(StateError('pusher:error ${data['message']}'));
          }
        default:
          // Eventos propios del canal (no los internos del protocolo).
          if (!name.startsWith('pusher') && decoded['channel'] == channel) {
            if (!events.isClosed) events.add((name: name, data: data));
          }
      }
    }

    final subscription = socket.messages.listen(
      onMessage,
      onError: (Object error, StackTrace stack) {
        if (!ready.isCompleted) ready.completeError(error, stack);
        if (!events.isClosed) unawaited(events.close());
      },
      onDone: () {
        if (!ready.isCompleted) {
          ready.completeError(StateError('socket cerrado'));
        }
        if (!events.isClosed) unawaited(events.close());
      },
    );
    final session = PusherChannelSession._(socket, subscription, events);
    try {
      await ready.future.timeout(const Duration(seconds: 20));
    } on Object {
      await session.close();
      rethrow;
    }
    return session;
  }

  /// `data` llega como texto JSON o ya como objeto.
  static Map<String, Object?> _dataOf(Object? raw) {
    Object? value = raw;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        return const {};
      }
    }
    return value is Map ? value.cast<String, Object?>() : const {};
  }
}
