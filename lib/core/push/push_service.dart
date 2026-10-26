import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'push_message.dart';

// Se reexporta [PushMessage] (movido a su propio archivo por SRP) para no romper
// a quienes importan `push/push_service.dart`.
export 'push_message.dart';

/// Inicializa Firebase con las credenciales de `config/*.json` (idempotente).
/// Devuelve `false` si no hay credenciales: el push queda desactivado.
Future<bool> initFirebaseFromConfig() async {
  final options = firebaseOptionsFromConfig();
  if (options == null) return false;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: options);
  }
  return true;
}

/// Mensajes FCM con la app en segundo plano o cerrada. Debe ser una función
/// top-level (corre en otro isolate). Los mensajes con bloque `notification`
/// los muestra el sistema solo; acá se muestran los que traen solo `data`.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) return;
  if (!await initFirebaseFromConfig()) return;
  final service = PushService();
  await service.initializeLocalNotifications(onTap: (_) {});
  await service.showMessage(service.messageFrom(message));
}

/// Plumbing de push con Firebase Cloud Messaging + notificaciones locales. No
/// conoce Riverpod: el `PushController` lo orquesta y traduce sus callbacks a
/// `PushStatus`. Centraliza el canal Android y el formato de los mensajes.
class PushService {
  PushService({
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseMessaging? messaging,
    Future<bool> Function()? initFirebase,
    Stream<RemoteMessage>? foregroundMessages,
    Stream<RemoteMessage>? openedMessages,
  }) : _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _messagingOverride = messaging,
       _initFirebase = initFirebase ?? initFirebaseFromConfig,
       _foregroundMessages = foregroundMessages,
       _openedMessages = openedMessages;

  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging? _messagingOverride;
  final Future<bool> Function() _initFirebase;
  final Stream<RemoteMessage>? _foregroundMessages;
  final Stream<RemoteMessage>? _openedMessages;
  final List<StreamSubscription<Object?>> _subs = [];

  // Se resuelve tarde: FirebaseMessaging.instance exige Firebase inicializado.
  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  /// Canal Android de la operación: avisos de ruta, entrega y andén. Alta
  /// prioridad porque se usan en terreno y no pueden pasar desapercibidos.
  static const AndroidNotificationChannel operationChannel =
      AndroidNotificationChannel(
        'operacion',
        'Operación',
        description:
            'Avisos de la operación logística (rutas, entregas, andén).',
        importance: Importance.high,
      );

  /// Inicializa Firebase, las notificaciones locales y los listeners de FCM.
  ///
  /// Devuelve `false` (sin tocar la plataforma) si faltan las credenciales de
  /// Firebase. [onToken] recibe el identificador push del dispositivo cada vez
  /// que FCM lo registra (FID, API vigente de firebase_messaging 17),
  /// [onUnregistered] cuando FCM lo da de baja y [onTap] el `payload` de la
  /// notificación tocada (para navegar a la bandeja).
  Future<bool> initialize({
    required void Function(String token) onToken,
    required void Function(String? payload) onTap,
    void Function()? onUnregistered,
  }) async {
    if (!await _initFirebase()) return false;

    await initializeLocalNotifications(onTap: onTap);
    if (_messagingOverride == null) {
      FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
    }

    // Idempotente: si initialize() se vuelve a llamar (p. ej. un reintento
    // desde "Activar notificaciones" tras un fallo parcial del init anterior),
    // se cancelan las suscripciones previas antes de recrearlas para no apilar
    // listeners duplicados de FCM (cada mensaje se mostraría/navegaría N veces).
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();

    _subs
      ..add(_messaging.onRegistered.listen(onToken))
      ..add(_messaging.onUnregistered.listen((_) => onUnregistered?.call()))
      // Con la app abierta FCM no muestra nada: se muestra con una local.
      ..add(
        (_foregroundMessages ?? FirebaseMessaging.onMessage).listen(
          (m) => unawaited(showMessage(messageFrom(m))),
        ),
      )
      // Notificación del sistema tocada con la app en segundo plano.
      ..add(
        (_openedMessages ?? FirebaseMessaging.onMessageOpenedApp).listen(
          (m) => onTap(payloadOf(m)),
        ),
      );

    // La app se abrió desde una notificación estando cerrada.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) onTap(payloadOf(initial));
    return true;
  }

  /// Notificaciones locales + canal Android "operacion".
  Future<void> initializeLocalNotifications({
    required void Function(String? payload) onTap,
  }) async {
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) =>
          onTap(response.payload),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(operationChannel);
  }

  /// Pide el permiso de notificaciones (Android 13+ / iOS). `true` si quedó
  /// concedido (o provisional).
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// ¿Ya estaba concedido el permiso? (sin volver a preguntar).
  Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Registra el dispositivo en FCM. El identificador llega por `onToken`
  /// (ver [initialize]) y viaja al backend como `device.push_token`.
  Future<void> registerDevice() => _messaging.register();

  /// Baja del push en este dispositivo: FCM invalida el identificador.
  Future<void> unregister() => _messaging.unregister();

  /// Suscribe a un topic FCM (p. ej. `NotificationView.fcmTopic` de un envío).
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  /// Muestra una notificación local a partir del mensaje recibido.
  Future<void> showMessage(PushMessage message) {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'operacion',
        'Operación',
        channelDescription:
            'Avisos de la operación logística (rutas, entregas, andén).',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    // Un id variable por tiempo evita que una notificación pise a la anterior.
    final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return _localNotifications.show(
      id,
      message.title,
      message.body,
      details,
      payload: message.payload,
    );
  }

  /// Normaliza un mensaje FCM a [PushMessage]. Prefiere el bloque
  /// `notification`; si no viene, usa `data` (`title`, `body`/`message`). Nunca
  /// lanza: ante contenido vacío cae a un aviso genérico.
  PushMessage messageFrom(RemoteMessage message) {
    final data = message.data;
    String? text(String key) {
      final value = data[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    final title = message.notification?.title;
    final body = message.notification?.body;
    return PushMessage(
      title: (title != null && title.isNotEmpty)
          ? title
          : text('title') ?? 'Operación',
      body: (body != null && body.isNotEmpty)
          ? body
          : text('body') ??
                text('message') ??
                'Tienes una novedad en la operación.',
      payload: payloadOf(message),
    );
  }

  /// Dato para navegar al tocar: id de notificación, de envío o el tag.
  String? payloadOf(RemoteMessage message) {
    for (final key in const ['notification_id', 'shipment_id', 'tag', 'id']) {
      final value = message.data[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  @visibleForTesting
  Future<void> dispose() => cancelSubscriptions();

  /// Cancela los listeners de FCM registrados por [initialize].
  Future<void> cancelSubscriptions() async {
    final subs = List.of(_subs);
    _subs.clear();
    for (final sub in subs) {
      await sub.cancel();
    }
  }
}
