import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:unifiedpush/unifiedpush.dart';

import 'push_message.dart';

// Se reexporta [PushMessage] (movido a su propio archivo por SRP) para no romper
// a quienes importan `push/push_service.dart`.
export 'push_message.dart';

/// Plumbing de push sin Firebase (UnifiedPush/ntfy + notificaciones locales,
/// ADR 014). No conoce Riverpod: el `PushController` lo orquesta y traduce sus
/// callbacks a [PushStatus]. Centraliza el canal Android y el formato de los
/// mensajes para que la capa de estado quede libre de detalles del SDK.
class PushService {
  PushService({FlutterLocalNotificationsPlugin? localNotifications})
    : _localNotifications =
          localNotifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _localNotifications;

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

  /// Inicializa UnifiedPush y las notificaciones locales.
  ///
  /// Registra los cuatro callbacks de UnifiedPush y prepara el canal Android.
  /// [onTap] se dispara cuando el usuario toca una notificación local y entrega
  /// el `payload` guardado (si lo hay), para navegar a la bandeja.
  Future<void> initialize({
    required void Function(String endpoint, String instance) onNewEndpoint,
    required void Function(String instance) onRegistrationFailed,
    required void Function(String instance) onUnregistered,
    required void Function(Uint8List message, String instance) onMessage,
    required void Function(String? payload) onTap,
  }) async {
    await UnifiedPush.initialize(
      onNewEndpoint: onNewEndpoint,
      onRegistrationFailed: onRegistrationFailed,
      onUnregistered: onUnregistered,
      onMessage: onMessage,
    );

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
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

  /// Pide el permiso de notificaciones (Android 13+, POST_NOTIFICATIONS).
  /// Devuelve `true` si quedó concedido.
  Future<bool> requestNotificationPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Distribuidores UnifiedPush instalados en el dispositivo (p. ej. ntfy).
  Future<List<String>> availableDistributors() => UnifiedPush.getDistributors();

  /// Distribuidor ya elegido/guardado en una ejecución previa, si existe.
  Future<String?> savedDistributor() => UnifiedPush.getDistributor();

  Future<void> saveDistributor(String distributor) =>
      UnifiedPush.saveDistributor(distributor);

  /// Pide un endpoint al distribuidor. El resultado llega de forma asíncrona
  /// por el callback `onNewEndpoint`.
  Future<void> register() => UnifiedPush.registerApp();

  /// Da de baja el registro en el distribuidor.
  Future<void> unregister() => UnifiedPush.unregister();

  /// Muestra una notificación local a partir del cuerpo recibido.
  Future<void> showMessage(PushMessage message) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'operacion',
          'Operación',
          channelDescription:
              'Avisos de la operación logística (rutas, entregas, andén).',
          importance: Importance.high,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
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

  /// Normaliza los bytes crudos del distribuidor a un [PushMessage].
  ///
  /// Intenta leerlos como JSON de ntfy (`title`, `message`, `tag`/`id`); si no
  /// es JSON, usa el texto plano como cuerpo. Nunca lanza: ante contenido raro
  /// cae a un aviso genérico para no perder el mensaje.
  PushMessage decodeMessage(Uint8List bytes) {
    const String fallbackTitle = 'Operación';
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      return const PushMessage(
        title: fallbackTitle,
        body: 'Tienes una novedad en la operación.',
      );
    }

    try {
      final Object? decoded = jsonDecode(text);
      if (decoded is Map<String, Object?>) {
        final Object? body = decoded['message'];
        final Object? title = decoded['title'];
        final Object? tag = decoded['tag'] ?? decoded['id'];
        return PushMessage(
          title: title is String && title.isNotEmpty ? title : fallbackTitle,
          body: body is String && body.isNotEmpty ? body : text,
          payload: tag is String && tag.isNotEmpty ? tag : null,
        );
      }
    } on FormatException {
      // No era JSON: se usa el texto plano como cuerpo.
    }

    return PushMessage(title: fallbackTitle, body: text);
  }
}
