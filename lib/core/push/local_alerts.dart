import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_service.dart';

/// Notificaciones del sistema que muestra LA APP MISMA, sin pasar por el
/// servicio de push: lo que llega por la conexión de tiempo real (un aviso de
/// la empresa) suena y aparece en la barra del teléfono igual que un push.
///
/// Funciona aunque el entorno no tenga push configurado. Nunca lanza: si el
/// teléfono no deja mostrar notificaciones, simplemente no se muestran.
class LocalAlerts {
  LocalAlerts([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  /// Al tocar una de estas notificaciones.
  void Function()? onTap;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (_) => onTap?.call(),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(PushService.operationChannel);
    _ready = true;
  }

  /// ACTIVA las notificaciones: prepara el canal y pide el permiso del
  /// sistema si hace falta (Android 13+ / iOS). `true` si quedaron permitidas.
  Future<bool> enable() async {
    try {
      await _init();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } on Object {
      return false;
    }
  }

  /// Muestra una notificación del sistema.
  Future<void> show({required String title, String? body}) async {
    try {
      await _init();
      await _plugin.show(
        // Un id por tiempo: una notificación no pisa a la anterior.
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'operacion',
            'Operación',
            channelDescription:
                'Avisos de la operación logística (rutas, entregas, andén).',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } on Object {
      // Sin permiso o sin plugin: no se muestra.
    }
  }
}

final localAlertsProvider = Provider<LocalAlerts>((ref) => LocalAlerts());
