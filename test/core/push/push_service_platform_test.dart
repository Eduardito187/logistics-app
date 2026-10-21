// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/push/push_service.dart';

// PushService contra FCM: FirebaseMessaging y las notificaciones locales son
// dobles inyectados; los streams de mensajes también. Cubre el cableado
// (registro, mensajes en primer plano, taps, permiso, topics) sin dispositivo.

class _FakeMessaging implements FirebaseMessaging {
  final registered = StreamController<String>.broadcast();
  final unregistered = StreamController<String>.broadcast();
  RemoteMessage? initialMessage;
  AuthorizationStatus status = AuthorizationStatus.authorized;
  final List<String> calls = [];

  @override
  Stream<String> get onRegistered => registered.stream;

  @override
  Stream<String> get onUnregistered => unregistered.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  NotificationSettings _settings() => NotificationSettings(
    alert: AppleNotificationSetting.notSupported,
    announcement: AppleNotificationSetting.notSupported,
    authorizationStatus: status,
    badge: AppleNotificationSetting.notSupported,
    carPlay: AppleNotificationSetting.notSupported,
    lockScreen: AppleNotificationSetting.notSupported,
    notificationCenter: AppleNotificationSetting.notSupported,
    showPreviews: AppleShowPreviewSetting.notSupported,
    timeSensitive: AppleNotificationSetting.notSupported,
    criticalAlert: AppleNotificationSetting.notSupported,
    sound: AppleNotificationSetting.notSupported,
    providesAppNotificationSettings: AppleNotificationSetting.notSupported,
  );

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    calls.add('requestPermission');
    return _settings();
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async => _settings();

  @override
  Future<void> register({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    calls.add('register');
    registered.add('fid-123');
  }

  @override
  Future<void> unregister() async {
    calls.add('unregister');
    unregistered.add('fid-123');
  }

  @override
  Future<void> subscribeToTopic(String topic) async =>
      calls.add('subscribe:$topic');

  @override
  Future<void> unsubscribeFromTopic(String topic) async =>
      calls.add('unsubscribe:$topic');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalNotifications implements FlutterLocalNotificationsPlugin {
  DidReceiveNotificationResponseCallback? onResponse;
  final List<({String? title, String? body, String? payload, String? channel})>
  shown = [];

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    onResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() => null;

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    shown.add((
      title: title,
      body: body,
      payload: payload,
      channel: notificationDetails?.android?.channelId,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeMessaging messaging;
  late _FakeLocalNotifications local;
  late StreamController<RemoteMessage> foreground;
  late StreamController<RemoteMessage> opened;

  PushService build({bool configured = true}) => PushService(
    messaging: messaging,
    localNotifications: local,
    initFirebase: () async => configured,
    foregroundMessages: foreground.stream,
    openedMessages: opened.stream,
  );

  setUp(() {
    messaging = _FakeMessaging();
    local = _FakeLocalNotifications();
    foreground = StreamController<RemoteMessage>.broadcast();
    opened = StreamController<RemoteMessage>.broadcast();
  });

  test('sin credenciales de Firebase no inicializa nada', () async {
    final service = build(configured: false);

    final ok = await service.initialize(onToken: (_) {}, onTap: (_) {});

    expect(ok, isFalse);
    expect(local.onResponse, isNull);
  });

  test('registerDevice entrega el identificador por onToken', () async {
    final tokens = <String>[];
    final service = build();
    await service.initialize(onToken: tokens.add, onTap: (_) {});

    await service.registerDevice();
    await pumpEventQueue();

    expect(tokens, ['fid-123']);
  });

  test('unregister avisa por onUnregistered', () async {
    var unregistered = 0;
    final service = build();
    await service.initialize(
      onToken: (_) {},
      onTap: (_) {},
      onUnregistered: () => unregistered++,
    );

    await service.unregister();
    await pumpEventQueue();

    expect(unregistered, 1);
  });

  test(
    'mensaje con la app abierta se muestra como notificación local',
    () async {
      final service = build();
      await service.initialize(onToken: (_) {}, onTap: (_) {});

      foreground.add(
        const RemoteMessage(
          notification: RemoteNotification(title: 'Ruta lista', body: 'Sal ya'),
          data: {'notification_id': 'N-7'},
        ),
      );
      await pumpEventQueue();

      final shown = local.shown.single;
      expect(shown.title, 'Ruta lista');
      expect(shown.body, 'Sal ya');
      expect(shown.payload, 'N-7');
      expect(shown.channel, PushService.operationChannel.id);
    },
  );

  test(
    'taps: notificación local, abierta desde segundo plano y de arranque',
    () async {
      messaging.initialMessage = const RemoteMessage(
        data: {'notification_id': 'N-arranque'},
      );
      final taps = <String?>[];
      final service = build();
      await service.initialize(onToken: (_) {}, onTap: taps.add);

      opened.add(const RemoteMessage(data: {'shipment_id': 'SHP-9'}));
      await pumpEventQueue();
      local.onResponse!(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'N-local',
        ),
      );

      expect(taps, ['N-arranque', 'SHP-9', 'N-local']);
    },
  );

  test('permiso: concedido, provisional y denegado', () async {
    final service = build();

    expect(await service.requestPermission(), isTrue);
    messaging.status = AuthorizationStatus.provisional;
    expect(await service.hasPermission(), isTrue);
    messaging.status = AuthorizationStatus.denied;
    expect(await service.requestPermission(), isFalse);
    expect(await service.hasPermission(), isFalse);
  });

  test('topics delegan en FCM (p. ej. fcm_topic del envío)', () async {
    final service = build();

    await service.subscribeToTopic('shipment_1');
    await service.unsubscribeFromTopic('shipment_1');

    expect(messaging.calls, ['subscribe:shipment_1', 'unsubscribe:shipment_1']);
  });
}
