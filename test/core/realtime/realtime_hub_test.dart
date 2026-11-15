import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/push/push_arrived.dart';
import 'package:logistics_app/core/realtime/pusher_socket.dart';
import 'package:logistics_app/core/realtime/realtime_bus.dart';
import 'package:logistics_app/core/realtime/realtime_hub.dart';

// Tiempo real: protocolo Pusher sobre un socket falso, y la conexión única
// que reparte los eventos por tema (usuario, flota, planes).

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

  /// El saludo del servidor.
  void hello() => receive(
    'pusher:connection_established',
    data: jsonEncode({'socket_id': '11.22', 'activity_timeout': 120}),
  );

  /// Canales a los que se pidió suscribir / desuscribir.
  List<Object?> channelsOf(String event) => [
    for (final message in sent)
      if (message['event'] == event) (message['data'] as Map)['channel'],
  ];
}

/// Dio que firma los canales (o responde un error) sin red.
class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter({this.status = 200, this.denied = const {}});

  final int status;

  /// Canales que el backend no autoriza (403).
  final Set<String> denied;
  final List<Object?> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    bodies.add(options.data);
    final channel = (options.data as Map?)?['channel_name'];
    final code = denied.contains(channel) ? 403 : status;
    return ResponseBody.fromString(
      jsonEncode(code == 200 ? {'auth': 'key:firma'} : {'title': 'x'}),
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Dio que responde siempre el mismo JSON.
class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body);

  final Map<String, Object?> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

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

Future<void> _wait([int ms = 30]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  test('URL de conexión: mismo host y puerto que la API', () {
    final uri = PusherConnection.endpoint(
      api: Uri.parse('http://137.131.245.152:8110/api/v1'),
      key: 'clave',
    );
    expect(uri.toString(), startsWith('ws://137.131.245.152:8110/app/clave?'));
    expect(uri.queryParameters['protocol'], '7');

    // Con la API en https va cifrado y sin puerto explícito.
    final secure = PusherConnection.endpoint(
      api: Uri.parse('https://logistics.dismac.com.bo/api/v1'),
      key: 'k',
      path: '/app/',
    );
    expect(
      secure.toString(),
      startsWith('wss://logistics.dismac.com.bo/app/k?'),
    );
  });

  group('conexión que da el backend', () {
    Future<RealtimeEndpoint?> load(Map<String, Object?> body) {
      final c = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(
            Dio(BaseOptions(baseUrl: 'http://10.0.0.5:8110/api/v1'))
              ..httpClientAdapter = _JsonAdapter(body),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c.read(realtimeEndpointProvider)();
    }

    test('toma la clave y los canales del endpoint, nada fijo', () async {
      final endpoint = await load({
        'enabled': true,
        'key': 'clave-staging',
        'cluster': null,
        'path': '/app',
        'channels': {
          'user': 'private-user.42',
          'fleet': ['private-fleet.SCZ', 'private-fleet.LPZ'],
          'planning': <String>[],
        },
      });
      expect(
        endpoint!.uri.toString(),
        startsWith('ws://10.0.0.5:8110/app/clave-staging?'),
      );
      expect(endpoint.channels['user'], ['private-user.42']);
      expect(endpoint.channels['fleet'], [
        'private-fleet.SCZ',
        'private-fleet.LPZ',
      ]);
      expect(endpoint.channels['planning'], isEmpty);
    });

    test('sin lista de canales (backend anterior)', () async {
      final endpoint = await load({
        'enabled': true,
        'key': 'k',
        'cluster': null,
        'path': '/app',
      });
      expect(endpoint!.channels, isEmpty);
    });

    test('entorno sin tiempo real', () async {
      expect(
        await load({
          'enabled': false,
          'key': null,
          'cluster': null,
          'path': '/app',
        }),
        isNull,
      );
    });
  });

  group('protocolo', () {
    test('suscribe con firma, entrega solo canales suscritos', () async {
      final socket = _Socket();
      final opening = PusherConnection.open(
        uri: Uri.parse('ws://h/app/k'),
        authorize: (socketId, channel) async => 'k:$socketId:$channel',
        connect: (_) async => socket,
      );
      await Future<void>.delayed(Duration.zero);
      socket.hello();
      final connection = await opening;
      await connection.subscribe('private-user.42');

      expect(socket.sent.single['event'], 'pusher:subscribe');
      expect(socket.sent.single['data'], {
        'auth': 'k:11.22:private-user.42',
        'channel': 'private-user.42',
      });

      final events = <RealtimeEvent>[];
      connection.events.listen(events.add);
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
      expect(events.single.channel, 'private-user.42');
      expect(events.single.data['unread'], 3);

      connection.unsubscribe('private-user.42');
      expect(socket.channelsOf('pusher:unsubscribe'), ['private-user.42']);
      expect(connection.channels, isEmpty);

      await connection.close();
      expect(socket.closed, isTrue);
    });

    test('si la firma de un canal falla, la conexión sigue', () async {
      final socket = _Socket();
      final opening = PusherConnection.open(
        uri: Uri.parse('ws://h/app/k'),
        authorize: (_, channel) async =>
            channel == 'private-no' ? throw StateError('403') : 'ok',
        connect: (_) async => socket,
      );
      await Future<void>.delayed(Duration.zero);
      socket.hello();
      final connection = await opening;

      await expectLater(connection.subscribe('private-no'), throwsStateError);
      expect(connection.channels, isEmpty);
      await connection.subscribe('private-si');
      expect(connection.channels, {'private-si'});
      expect(socket.closed, isFalse);
      await connection.close();
    });

    test('si el servidor corta antes del saludo, falla', () async {
      final socket = _Socket();
      final opening = PusherConnection.open(
        uri: Uri.parse('ws://h/app/k'),
        authorize: (_, _) async => 'ok',
        connect: (_) async => socket,
      );
      final failed = expectLater(opening, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      await socket.close();
      await failed;
    });
  });

  group('conexión de la app', () {
    ProviderContainer container(
      _Socket socket,
      _AuthAdapter auth, {
      Map<String, List<String>> channels = const {},
    }) {
      final c = ProviderContainer(
        overrides: [
          realtimeEndpointProvider.overrideWithValue(
            () async =>
                (uri: Uri.parse('ws://h:8110/app/k'), channels: channels),
          ),
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

    Future<void> start(ProviderContainer c, _Socket socket) async {
      c.listen(realtimeHubProvider, (_, _) {});
      c.listen(realtimeLiveProvider, (_, _) {});
      await _wait(5);
      socket.hello();
      await _wait();
    }

    test('un aviso o una notificación nueva refresca las bandejas', () async {
      final socket = _Socket();
      final auth = _AuthAdapter();
      final c = container(socket, auth);
      await start(c, socket);

      // Sin lista de canales, el del usuario se arma con su id.
      expect(auth.bodies.single, {
        'socket_id': '11.22',
        'channel_name': 'private-user.42',
      });
      expect(c.read(realtimeLiveProvider), {RealtimeTopic.user});

      var before = c.read(pushArrivedProvider);
      socket.receive(
        'inbox.updated',
        data: {'unread': 2},
        channel: 'private-user.42',
      );
      await _wait();
      expect(c.read(pushArrivedProvider), before + 1);

      before = c.read(pushArrivedProvider);
      socket.receive('notifications.updated', channel: 'private-user.42');
      await _wait();
      expect(c.read(pushArrivedProvider), before + 1);
    });

    test('un tema se suscribe solo mientras una pantalla lo escucha', () async {
      final socket = _Socket();
      final c = container(
        socket,
        _AuthAdapter(),
        channels: {
          'user': ['private-user.42'],
          'fleet': ['private-fleet.SCZ'],
        },
      );
      await start(c, socket);
      expect(socket.channelsOf('pusher:subscribe'), ['private-user.42']);

      final received = <RealtimeEvent>[];
      final stop = c
          .read(realtimeBusProvider)
          .listen(RealtimeTopic.fleet, received.add);
      await _wait();
      expect(socket.channelsOf('pusher:subscribe'), [
        'private-user.42',
        'private-fleet.SCZ',
      ]);
      expect(c.read(realtimeTopicLiveProvider(RealtimeTopic.fleet)), isTrue);

      socket.receive(
        'fleet.position',
        data: {'vehicle_id': 'v1'},
        channel: 'private-fleet.SCZ',
      );
      await _wait();
      expect(received.single.name, 'fleet.position');
      expect(received.single.data['vehicle_id'], 'v1');

      stop();
      await _wait();
      expect(socket.channelsOf('pusher:unsubscribe'), ['private-fleet.SCZ']);
      expect(c.read(realtimeTopicLiveProvider(RealtimeTopic.fleet)), isFalse);
      expect(c.read(realtimeTopicLiveProvider(RealtimeTopic.user)), isTrue);
    });

    test('tema pedido antes de conectar se suscribe al conectar', () async {
      final socket = _Socket();
      final c = container(
        socket,
        _AuthAdapter(),
        channels: {
          'planning': ['private-planning.SCZ'],
        },
      );
      c.read(realtimeBusProvider).listen(RealtimeTopic.planning, (_) {});
      await start(c, socket);

      expect(c.read(realtimeLiveProvider), {
        RealtimeTopic.user,
        RealtimeTopic.planning,
      });
    });

    test('tema sin canales o sin permiso: queda en respaldo', () async {
      final socket = _Socket();
      final c = container(
        socket,
        _AuthAdapter(denied: {'private-fleet.SCZ'}),
        channels: {
          'fleet': ['private-fleet.SCZ'],
        },
      );
      await start(c, socket);
      final bus = c.read(realtimeBusProvider);
      bus.listen(RealtimeTopic.fleet, (_) {});
      bus.listen(RealtimeTopic.planning, (_) {});
      await _wait();

      expect(c.read(realtimeLiveProvider), {RealtimeTopic.user});
      expect(socket.closed, isFalse);
    });

    test('si la conexión se cae, los temas dejan de estar en vivo', () async {
      final socket = _Socket();
      final c = container(socket, _AuthAdapter());
      await start(c, socket);
      expect(c.read(realtimeLiveProvider), isNotEmpty);

      await socket.close();
      await _wait();
      expect(c.read(realtimeLiveProvider), isEmpty);
    });

    test('entorno sin sockets (503): no insiste', () async {
      final socket = _Socket();
      final c = container(socket, _AuthAdapter(status: 503));
      await start(c, socket);

      expect(socket.closed, isTrue);
      expect(c.read(realtimeLiveProvider), isEmpty);
    });

    test('si el backend dice que no hay tiempo real, no conecta', () async {
      var connects = 0;
      final c = ProviderContainer(
        overrides: [
          realtimeEndpointProvider.overrideWithValue(() async => null),
          realtimeConnectorProvider.overrideWithValue((_) async {
            connects++;
            return _Socket();
          }),
          sessionProvider.overrideWith(_Session.new),
        ],
      );
      addTearDown(c.dispose);
      c.listen(realtimeHubProvider, (_, _) {});
      await _wait();

      expect(connects, 0);
      expect(c.read(realtimeLiveProvider), isEmpty);
    });
  });
}
