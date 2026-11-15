import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Conexión mínima a un servidor de sockets con protocolo Pusher (Soketi).
///
/// Solo lo que la app necesita: conectarse, suscribirse a canales (los
/// privados, con la firma que da el backend) y recibir sus eventos. Sin
/// dependencias: usa el `WebSocket` de `dart:io`. La reconexión la decide
/// quien la usa.
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

/// Un evento recibido en un canal.
typedef RealtimeEvent = ({
  String channel,
  String name,
  Map<String, Object?> data,
});

/// Firma la suscripción a un canal privado (`"<key>:<firma>"`).
typedef ChannelAuthorizer =
    Future<String> Function(String socketId, String channel);

/// Una conexión con varios canales: conecta, suscribe/desuscribe y entrega
/// los eventos de los canales suscritos. [done] se completa cuando la
/// conexión se cae o se cierra.
class PusherConnection {
  PusherConnection._(this._socket, this._authorize);

  final RealtimeSocket _socket;
  final ChannelAuthorizer _authorize;
  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();
  final Set<String> _channels = {};
  StreamSubscription<Object?>? _subscription;
  String? _socketId;

  Stream<RealtimeEvent> get events => _events.stream;

  /// Se completa cuando la conexión termina (caída o [close]).
  Future<void> get done => _events.done;

  /// Canales suscritos en este momento.
  Set<String> get channels => Set.unmodifiable(_channels);

  Future<void> close() async {
    await _subscription?.cancel();
    try {
      await _socket.close();
    } on Object {
      // Ya estaba cerrada.
    }
    if (!_events.isClosed) await _events.close();
  }

  /// URL de conexión del protocolo Pusher. El servidor de sockets se publica
  /// por el MISMO host y puerto que la API ([api]); `wss` si la API es https.
  static Uri endpoint({
    required Uri api,
    required String key,
    String path = '/app',
  }) => Uri(
    scheme: api.scheme == 'https' ? 'wss' : 'ws',
    host: api.host,
    port: api.hasPort ? api.port : null,
    path:
        '${path.endsWith('/') ? path.substring(0, path.length - 1) : path}/$key',
    queryParameters: const {
      'protocol': '7',
      'client': 'distrack',
      'version': '1.0',
    },
  );

  /// Conecta a [uri] y espera el saludo del servidor. Lanza si la conexión
  /// falla (quien llama decide si reintenta).
  static Future<PusherConnection> open({
    required Uri uri,
    required ChannelAuthorizer authorize,
    RealtimeSocketConnector connect = connectIoSocket,
  }) async {
    final socket = await connect(uri);
    final connection = PusherConnection._(socket, authorize);
    final ready = Completer<void>();
    connection._subscription = socket.messages.listen(
      (raw) => connection._onMessage(raw, ready),
      onError: (Object error, StackTrace stack) {
        if (!ready.isCompleted) ready.completeError(error, stack);
        if (!connection._events.isClosed) unawaited(connection._events.close());
      },
      onDone: () {
        if (!ready.isCompleted) {
          ready.completeError(StateError('socket cerrado'));
        }
        if (!connection._events.isClosed) unawaited(connection._events.close());
      },
    );
    try {
      await ready.future.timeout(const Duration(seconds: 20));
    } on Object {
      await connection.close();
      rethrow;
    }
    return connection;
  }

  /// Se suscribe a [channel] (firmándolo si es privado). Lanza si la firma
  /// falla: ese canal queda sin suscribir y la conexión sigue.
  Future<void> subscribe(String channel) async {
    final socketId = _socketId;
    if (socketId == null || _events.isClosed) {
      throw StateError('sin conexión');
    }
    if (!_channels.add(channel)) return;
    try {
      final auth = channel.startsWith('private-')
          ? await _authorize(socketId, channel)
          : null;
      // Mientras se firmaba pudo cerrarse o desuscribirse.
      if (_events.isClosed || !_channels.contains(channel)) return;
      _socket.send(
        jsonEncode({
          'event': 'pusher:subscribe',
          'data': {'auth': ?auth, 'channel': channel},
        }),
      );
    } on Object {
      _channels.remove(channel);
      rethrow;
    }
  }

  void unsubscribe(String channel) {
    if (!_channels.remove(channel) || _events.isClosed) return;
    _socket.send(
      jsonEncode({
        'event': 'pusher:unsubscribe',
        'data': {'channel': channel},
      }),
    );
  }

  void _onMessage(Object? raw, Completer<void> ready) {
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
        _socketId = socketId;
        if (!ready.isCompleted) ready.complete();
      case 'pusher:ping':
        _socket.send(jsonEncode({'event': 'pusher:pong', 'data': {}}));
      case 'pusher:error':
        if (!ready.isCompleted) {
          ready.completeError(StateError('pusher:error ${data['message']}'));
        }
      default:
        // Eventos propios de un canal suscrito (no los internos del protocolo).
        final channel = decoded['channel'];
        if (!name.startsWith('pusher') &&
            channel is String &&
            _channels.contains(channel) &&
            !_events.isClosed) {
          _events.add((channel: channel, name: name, data: data));
        }
    }
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
