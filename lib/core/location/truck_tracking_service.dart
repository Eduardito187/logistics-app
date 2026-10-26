import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/export.dart';
import '../auth/session.dart';
import '../offline/offline_queue.dart';
import 'location_service.dart';
import 'truck_tracking_state.dart';

// Se reexporta [TruckTrackingState] (movido a su propio archivo por SRP) para no
// romper a quienes importan `location/truck_tracking_service.dart`.
export 'truck_tracking_state.dart';

/// Canal de notificación del rastreo en vivo. Android exige una notificación
/// visible y persistente mientras el foreground service está activo.
const String _trackingChannelId = 'dismac_truck_tracking';
const String _trackingChannelName = 'Rastreo del camión';

/// Rastreo del camión en primer plano (foreground service).
///
/// El rastreo es OBLIGATORIO y AUTOMÁTICO: no hay botón de iniciar/detener ni
/// envío manual de posiciones. Arranca solo cuando el chofer tiene un envío/ruta
/// activos (ver `driver_tracking_autostart.dart`) y se detiene al terminar la
/// ruta o cerrar sesión. No se confía en que el chofer lo encienda.
///
/// Decisión de diseño: la captura de posiciones y el encolado se hacen en el
/// isolate principal, reutilizando [LocationService] y [OfflineQueue]. El
/// foreground service de `flutter_foreground_task` se usa sólo para mantener el
/// proceso vivo con la app en segundo plano (Android mata los procesos en
/// background, pero respeta un servicio en primer plano con notificación).
///
/// El round-trip del stream de geolocator hacia el isolate del task handler
/// obligaría a reconstruir allí la base de datos (drift) y los providers de
/// Riverpod; no aporta y complica. Por eso el `eventAction` del task es
/// `nothing()`: no corre callback en el isolate secundario, sólo se mantiene el
/// servicio. El `allowWakeLock` evita que el CPU se duerma y corte el GPS.
///
/// Realidad de la plataforma (segundo plano):
///  - Android: un foreground service de ubicación EXIGE una notificación
///    persistente y visible mientras corre; el sistema no permite ocultarla.
///    Esto es, además, deseable para este caso de uso: deja a la vista que el
///    camión se está rastreando y refuerza que el rastreo no se puede apagar a
///    escondidas. Requiere los permisos `FOREGROUND_SERVICE_LOCATION`,
///    `ACCESS_BACKGROUND_LOCATION` y `POST_NOTIFICATIONS` (ya declarados en el
///    manifest). Si el usuario niega POST_NOTIFICATIONS (Android 13+), el
///    servicio igual corre, pero el sistema puede no mostrar el aviso.
///  - iOS: se usa background location (modo declarado en Info.plist). iOS puede
///    suspender la app y entregar las posiciones en ráfagas según batería y
///    movimiento; la cadencia no es tan firme como en Android.
///  - Límites comunes: optimización de batería agresiva del fabricante, GPS sin
///    señal (túnel, sótano) o servicio de ubicación apagado pueden cortar el
///    flujo. Por eso cada posición se encola offline-first y se sincroniza al
///    recuperar señal; nunca se pierde por falta de red momentánea.
class TruckTrackingService extends Notifier<TruckTrackingState> {
  /// Separación mínima entre posiciones encoladas. Cada posición es una fila
  /// en la cola local y un POST: a 60 km/h con filtro de 20 m serían ~3000 por
  /// hora. Con 10 s quedan ~360/h, suficiente para el seguimiento en vivo.
  static const Duration minFixInterval = Duration(seconds: 10);

  StreamSubscription<GpsFix>? _sub;

  /// Momento de la última posición encolada (para [minFixInterval]).
  DateTime? _lastEnqueuedAt;
  bool _channelReady = false;

  /// Envío al que se asocian las posiciones capturadas. Se puede re-apuntar en
  /// caliente cuando la parada en curso cambia, sin reiniciar el servicio.
  String? _shipmentId;

  @override
  TruckTrackingState build() {
    // Detener el rastreo al cerrar sesión: el foreground service sobrevive a la
    // navegación, así que no alcanza con que la UI se desmonte. Escuchar la
    // sesión acá (provider de larga vida) garantiza que el camión deje de
    // rastrearse apenas el chofer sale, pase lo que pase en la UI.
    ref.listen<Session?>(sessionProvider, (previous, next) {
      if (next == null && state.active) {
        unawaited(stop());
      }
    });
    ref.onDispose(() {
      unawaited(_sub?.cancel());
    });
    return const TruckTrackingState();
  }

  /// Configura el canal de notificación y las opciones del servicio. Idempotente.
  void _ensureChannel() {
    if (_channelReady) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _trackingChannelId,
        channelName: _trackingChannelName,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Sin callback en el isolate secundario: la captura va en el principal.
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _channelReady = true;
  }

  /// Inicia (o re-apunta) el rastreo del envío [shipmentId]. Levanta el
  /// foreground service y se suscribe al stream de GPS. Devuelve `false` si
  /// falta el permiso de ubicación "siempre" o si el servicio no pudo arrancar.
  ///
  /// Si ya está activo, no reinicia el servicio: sólo re-apunta el envío
  /// asociado (la parada en curso puede cambiar durante la ruta), de modo que
  /// las posiciones siguientes se encolan con el `shipmentId` vigente.
  ///
  /// El permiso de segundo plano debe estar concedido antes (el gate de
  /// ubicación lo exige al entrar a la operación); acá se vuelve a verificar
  /// para no arrancar un servicio que no podrá leer la ubicación.
  Future<bool> start({required String shipmentId}) async {
    if (state.active) {
      _shipmentId = shipmentId;
      state = state.copyWith(shipmentId: shipmentId);
      return true;
    }
    // Arranque en curso (permisos, servicio): una segunda llamada antes de que
    // termine NO abre otro stream de GPS; se suma al arranque y re-apunta.
    final starting = _starting;
    if (starting != null) {
      _pendingShipmentId = shipmentId;
      return starting;
    }
    final run = _start(shipmentId);
    _starting = run;
    try {
      return await run;
    } finally {
      _starting = null;
    }
  }

  /// Arranque en curso; las llamadas concurrentes a [start] se suman.
  Future<bool>? _starting;

  /// Envío pedido por una llamada concurrente durante el arranque.
  String? _pendingShipmentId;

  Future<bool> _start(String shipmentId) async {
    _pendingShipmentId = null;
    final location = ref.read(locationServiceProvider);
    if (!await location.ensureBackgroundPermission()) return false;

    _ensureChannel();

    // Pedir el permiso de notificación (Android 13+) para que la notificación
    // persistente del servicio sea visible; si se niega, el servicio igual
    // corre pero el sistema puede ocultar el aviso.
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'DisTrack',
      notificationText: 'Registrando ubicación del camión',
    );
    if (result is ServiceRequestFailure) return false;

    final current = _pendingShipmentId ?? shipmentId;
    _pendingShipmentId = null;
    _shipmentId = current;
    _lastEnqueuedAt = null;
    // Nunca dos suscripciones al GPS a la vez.
    await _sub?.cancel();
    _sub = location.stream().listen(_onFix);
    state = TruckTrackingState(
      active: true,
      shipmentId: current,
      sent: 0,
      lastFix: null,
    );
    return true;
  }

  /// Detiene el rastreo y baja el foreground service.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _shipmentId = null;
    await FlutterForegroundTask.stopService();
    state = state.copyWith(active: false);
  }

  /// Encola una posición capturada con el envío vigente. Mismo contrato de
  /// siempre: kind `ingestTruckPosition` + `@shipmentId` en el payload
  /// (offline-first, nunca espera a la red).
  void _onFix(GpsFix fix) {
    final shipmentId = _shipmentId;
    if (shipmentId == null) return;
    final now = DateTime.now();
    final last = _lastEnqueuedAt;
    // Lecturas demasiado seguidas se descartan: ni fila, ni POST, ni rebuild.
    if (last != null && now.difference(last) < minFixInterval) return;
    _lastEnqueuedAt = now;
    state = state.copyWith(lastFix: fix);
    final payload = <String, Object?>{
      ...TruckPositionInput(
        lat: fix.lat,
        lng: fix.lng,
        reportedAt: now,
      ).toJson(),
      '@shipmentId': shipmentId,
    };
    unawaited(
      ref
          .read(offlineQueueProvider)
          .submit(
            kind: 'ingestTruckPosition',
            payload: payload,
            label: 'GPS · $shipmentId',
            occurredAt: now,
          )
          .then((_) {
            state = state.copyWith(sent: state.sent + 1);
          }),
    );
  }
}

final truckTrackingProvider =
    NotifierProvider<TruckTrackingService, TruckTrackingState>(
      TruckTrackingService.new,
    );
