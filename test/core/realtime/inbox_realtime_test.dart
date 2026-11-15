import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/push/push_arrived.dart';
import 'package:logistics_app/core/realtime/inbox_realtime.dart';
import 'package:logistics_app/core/realtime/pusher_socket.dart';

// Avisos en tiempo real: protocolo Pusher sobre un socket falso, y el
// notifier que refresca las bandejas cuando llega "inbox.updated".

class _Socket implements RealtimeSocket {
  final _incoming = StreamController<Object?>();
  final List<Map<String, Object?>> sent = [];
  bool closed = false;

  @override
  Stream<Object?> get messages => _incoming.stream;

  @override
  void send(String data) =>
      sent.add((jsonDecode(data) as Map).cast<String, Object?>());

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }

  void receive(String event, {Object? data, String? channel}) => _incoming.add(
    jsonEncode({'event': event, 'data': ?data, 'channel': ?channel}),
  );

  /// El saludo del servidor y la confirmación de la suscripción.
  Future<void> handshake() async {
    receive(
      'pusher:connection_established',
      data: jsonEncode({'socket_id': '11.22', 'activity_timeout': 120}),
    );
    await Future<void>.delayed(Duration.zero);
    receive('pusher_internal:subscription_succeeded', channel: 'x');
    await Future<void>.delayed(Duration.zero);
  }
}

/// Dio que responde la firma del canal (o un error) sin red.
class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter(this.status);

  final int status;
  final List<Object?> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    bodies.add(options.data);
    return ResponseBody.fromString(
      jsonEncode(status == 200 ? {'auth': 'key:firma'} : {'title': 'x'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Sesión fija con el usuario 42.
class _Session extends SessionNotifier {
  @override
  Session? build() => const Session(
    userName: 'Ana',
    role: UserRole.store,
    token: 't',
    userId: 42,
  );
}

void main() {
  test('URL de conexión del protocolo', () {
    final uri = PusherChannelSession.endpoint(
      host: '10.0.2.2',
      port: 6001,
      key: 'dismaclocalkey',
      tls: false,
    );
    expect(uri.toString(), startsWith('ws://10.0.2.2:6001/app/dismaclocalkey'));
    expect(uri.queryParameters['protocol'], '7');
  });

  test(
    'se suscribe con la firma y entrega solo los eventos del canal',
    () async {
      final socket = _Socket();
      final opening = PusherChannelSession.open(
        uri: Uri.parse('ws://h/app/k'),
        channel: 'private-user.42',
        authorize: (socketId, channel) async => 'k:$socketId:$channel',
        connect: (_) async => socket,
      );
      await Future<void>.delayed(Duration.zero);
      await socket.handshake();
      final session = await opening;

      expect(socket.sent.single['event'], 'pusher:subscribe');
      expect(socket.sent.single['data'], {
        'auth': 'k:11.22:private-user.42',
        'channel': 'private-user.42',
      });

      final events = <RealtimeEvent>[];
      session.events.listen(events.add);
      socket
        ..receive('pusher:ping')
        ..receive('inbox.updated', data: '{"unread":3}', channel: 'otro')
        ..receive(
          'inbox.updated',
          data: '{"unread":3}',
          channel: 'private-user.42',
        );
      await Future<void>.delayed(Duration.zero);

      expect(socket.sent.last['event'], 'pusher:pong');
      expect(events.single.name, 'inbox.updated');
      expect(events.single.data['unread'], 3);

      await session.close();
      expect(socket.closed, isTrue);
    },
  );

  test('si la firma falla, no queda conectado', () async {
    final socket = _Socket();
    final opening = PusherChannelSession.open(
      uri: Uri.parse('ws://h/app/k'),
      channel: 'private-user.42',
      authorize: (_, _) async => throw StateError('403'),
      connect: (_) async => socket,
    );
    final failed = expectLater(opening, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    socket.receive(
      'pusher:connection_established',
      data: jsonEncode({'socket_id': '1.2'}),
    );
    await failed;
    expect(socket.closed, isTrue);
  });

  group('notifier', () {
    ProviderContainer container(_Socket socket, _AuthAdapter auth) {
      final c = ProviderContainer(
        overrides: [
          realtimeConfigProvider.overrideWithValue((
            host: 'h',
            port: 6001,
            key: 'k',
            tls: false,
          )),
          realtimeConnectorProvider.overrideWithValue((_) async => socket),
          dioProvider.overrideWithValue(
            Dio(BaseOptions(baseUrl: 'http://x/api/v1'))
              ..httpClientAdapter = auth,
          ),
          sessionProvider.overrideWith(_Session.new),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'un aviso nuevo refresca las bandejas y guarda los sin leer',
      () async {
        final socket = _Socket();
        final auth = _AuthAdapter(200);
        final c = container(socket, auth);
        c.listen(inboxRealtimeProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        await socket.handshake();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(auth.bodies.single, {
          'socket_id': '11.22',
          'channel_name': 'private-user.42',
        });
        final before = c.read(pushArrivedProvider);

        socket.receive(
          'inbox.updated',
          data: {'unread': 2},
          channel: 'private-user.42',
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(c.read(inboxRealtimeProvider), 2);
        expect(c.read(pushArrivedProvider), before + 1);
      },
    );

    test('entorno sin sockets (503): no insiste', () async {
      final socket = _Socket();
      final c = container(socket, _AuthAdapter(503));
      c.listen(inboxRealtimeProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      socket.receive(
        'pusher:connection_established',
        data: jsonEncode({'socket_id': '1.2'}),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(socket.closed, isTrue);
      expect(c.read(inboxRealtimeProvider), isNull);
    });

    test('sin configuración del entorno no conecta', () async {
      var connects = 0;
      final c = ProviderContainer(
        overrides: [
          realtimeConfigProvider.overrideWithValue(null),
          realtimeConnectorProvider.overrideWithValue((_) async {
            connects++;
            return _Socket();
          }),
          sessionProvider.overrideWith(_Session.new),
        ],
      );
      addTearDown(c.dispose);
      c.listen(inboxRealtimeProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      expect(connects, 0);
    });
  });
}
