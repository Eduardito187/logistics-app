import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/export.dart';
import '../auth/session.dart';
import '../live_updates/route_live_notification.dart';
import '../offline/offline_queue.dart';
import '../power/power_status.dart';
import '../power/power_status_notifier.dart';
import 'location_service.dart';
import 'motion_detector.dart';
import 'truck_tracking_state.dart';

// Se reexporta [TruckTrackingState] (movido a su propio archivo por SRP) para no
// romper a quienes importan `location/truck_tracking_service.dart`.
export 'truck_tracking_state.dart';

/// Canal de notificación del rastreo en vivo. Android exige una notificación
/// visible y persistente mientras el foreground service está activo.
///
/// UNA sola notificación (nov 2026): el servicio arranca con
/// `serviceId: routeLiveNotificationId` (4120), el mismo id de la ruta en vivo
/// (`LiveUpdatesChannel.kt`). El plugin postea primero su texto neutro en este
/// canal y la ruta en vivo lo reemplaza enseguida con su contenido (canal
/// "route_live"; Android conserva la marca de foreground service porque el id
/// es el del servicio). Ver `docs/live-updates.md`.
const String _trackingChannelId = 'dismac_truck_tracking';
// Nombre del canal NEUTRAL: el usuario lo ve en los ajustes de notificaciones
// del sistema; no debe revelar el rastreo de ubicación.
const String _trackingChannelName = 'Sesión en curso';

/// Una posición capturada y todavía no encolada (lote en memoria).
typedef _PendingFix = ({String shipmentId, GpsFix fix, DateTime at});

/// Rastreo del camión en primer plano (foreground service).
///
/// El rastreo es OBLIGATORIO y AUTOMÁTICO: no hay botón de iniciar/detener ni
/// envío manual de posiciones. Arranca solo cuando el chofer tiene un envío/ruta
/// activos (ver `driver_tracking_autostart.dart`) y se detiene al terminar la
/// ruta o cerrar sesión. No se confía en que el chofer lo encienda.
///
/// **Batería (nov 2026).** El rastreo era el mayor consumo de la app: GPS en
/// alta precisión cada 10 s todo el día y un POST por posición (la radio
/// celular nunca se dormía). Ahora es ADAPTATIVO (ver [TrackingProfile]):
/// - [MotionDetector] decide si el camión está en marcha o detenido; detenido
///   pasa a precisión balanceada (sin chip GPS) y lecturas cada 60 s.
/// - Las posiciones se juntan en memoria y se encolan/envían en ráfaga cada
///   60 s (la primera de cada arranque sale enseguida para que el supervisor
///   vea el camión al toque). Una posición casi igual a la anterior no se
///   reenvía; con el camión quieto sale un latido cada 5 min.
/// - Con ahorro de energía o batería < 20 % ([powerStatusProvider]) todo se
///   espacia el doble.
/// El lote se vacía al pasar a segundo plano, al detener y al cambiar de
/// envío, así que como mucho se pierde 1 min de posiciones si el SO mata la
/// app sin aviso (aceptable para telemetría; los escaneos siguen igual).
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
/// servicio. El `allowWakeLock` evita que el CPU se duerma y corte el GPS (y
/// los timers del lote) mientras la app está en segundo plano.
///
/// Realidad de la plataforma (segundo plano):
///  - Android: un foreground service de ubicación EXIGE una notificación
///    persistente y visible mientras corre; el sistema no permite ocultarla.
///    Requiere los permisos `FOREGROUND_SERVICE_LOCATION`,
///    `ACCESS_BACKGROUND_LOCATION` y `POST_NOTIFICATIONS` (ya declarados en el
///    manifest). Si el usuario niega POST_NOTIFICATIONS (Android 13+), el
///    servicio igual corre, pero el sistema puede no mostrar el aviso.
///  - iOS: se usa background location (modo declarado en Info.plist). iOS puede
///    entregar las posiciones en ráfagas según batería y movimiento; la
///    cadencia no es tan firme como en Android.
///  - Límites comunes: optimización de batería agresiva del fabricante, GPS sin
///    señal (túnel, sótano) o servicio de ubicación apagado pueden cortar el
///    flujo. Por eso cada posición se encola offline-first y se sincroniza al
///    recuperar señal; nunca se pierde por falta de red momentánea.
class TruckTrackingService extends Notifier<TruckTrackingState> {
  /// Separación mínima entre posiciones encoladas en marcha (perfil normal).
  /// Se mantiene por compatibilidad: el valor vigente lo da el perfil activo.
  static const Duration minFixInterval = Duration(seconds: 15);

  /// Distancia mínima (m) a la última posición encolada para encolar otra; por
  /// debajo es el mismo lugar (jitter) y solo cuenta el latido.
  static const double minEnqueueMeters = 25;

  /// Tope del lote en memoria: llegado a esta cantidad se envía ya.
  static const int maxBatch = 10;

  /// Reloj (tests).
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  StreamSubscription<GpsFix>? _sub;

  /// Momento y posición de la última encolada (throttle y deduplicado).
  DateTime? _lastEnqueuedAt;
  GpsFix? _lastEnqueuedFix;
  bool _channelReady = false;

  /// Envío al que se asocian las posiciones capturadas. Se puede re-apuntar en
  /// caliente cuando la parada en curso cambia, sin reiniciar el servicio.
  String? _shipmentId;

  /// Observa primer plano / segundo plano para mostrar la notificación del
  /// servicio SOLO cuando hace falta (ver [_onLifecycleChange]).
  AppLifecycleListener? _lifecycle;

  /// Detector en marcha / detenido y perfil vigente del GPS.
  final MotionDetector _motion = MotionDetector();
  TrackingProfile _profile = TrackingProfile.moving;

  /// Posiciones juntadas a la espera del próximo envío por lote.
  final List<_PendingFix> _batch = <_PendingFix>[];
  DateTime? _lastFlushAt;
  bool _firstFixSent = false;

  Timer? _flushTimer;
  Timer? _stillTimer;
  Timer? _heartbeatTimer;

  /// Perfil del GPS vigente (tests / diagnóstico).
  TrackingProfile get profile => _profile;

  @override
  TruckTrackingState build() {
    // Detener el rastreo al cerrar sesión: el foreground service sobrevive a la
    // navegación, así que no alcanza con que la UI se desmonte. Escuchar la
    // sesión acá (provider de larga vida) garantiza que el camión deje de
    // rastrearse apenas el chofer sale, pase lo que pase en la UI.
    ref.listen<Session?>(sessionProvider, (previous, next) {
      // Al cerrar sesión se baja SIEMPRE (no solo si el estado en memoria lo
      // cree activo): `stop` es seguro aunque no haya nada activo y así no queda
      // colgada la notificación de un servicio que sobrevivió a un reinicio.
      if (next == null) {
        unawaited(stop());
      }
    });
    // Ahorro de energía / batería baja: re-ajusta el perfil del GPS en caliente.
    ref.listen<PowerStatus>(powerStatusProvider, (previous, next) {
      if (previous?.shouldSaveEnergy != next.shouldSaveEnergy) {
        _applyProfile();
      }
    });
    // Notificación "fantasma": el servicio en primer plano (y su notificación,
    // que Android EXIGE en segundo plano) se levanta SOLO cuando la app pasa a
    // segundo plano, y se baja al volver al primer plano. Así el chofer nunca ve
    // la notificación mientras usa la app, y el rastreo sigue con la app cerrada.
    try {
      _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChange);
    } on Object {
      // Sin WidgetsBinding (tests unitarios sin widgets): sin toggle de ciclo de
      // vida. En producción (runApp) el binding siempre existe.
      _lifecycle = null;
    }
    ref.onDispose(() {
      _lifecycle?.dispose();
      _cancelTimers();
      unawaited(_sub?.cancel());
    });
    return const TruckTrackingState();
  }

  /// Primer plano ↔ segundo plano: muestra u oculta la notificación del servicio
  /// mientras el rastreo está activo. Sin rastreo activo no hace nada.
  void _onLifecycleChange(AppLifecycleState ls) {
    if (!state.active) return;
    switch (ls) {
      case AppLifecycleState.resumed:
        // De vuelta en la app: la ubicación en primer plano no necesita el
        // servicio → se baja y la notificación desaparece.
        unawaited(_stopForegroundService());
      case AppLifecycleState.paused:
        // La app pasó a segundo plano: se levanta el servicio (con su
        // notificación) para que Android no mate el proceso y el GPS siga. El
        // lote en memoria se encola ya (si el SO mata el proceso no se pierde).
        unawaited(_flush());
        unawaited(_startForegroundService());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // Transiciones intermedias (bandeja, multitarea) o cierre: no se togglea
        // para no parpadear ni duplicar; `paused`/`resumed` hacen el trabajo y
        // `stop`/`dispose` cubren el cierre real.
        break;
    }
  }

  /// `true` si la app está en segundo plano en este momento.
  bool get _isBackground {
    try {
      final ls = WidgetsBinding.instance.lifecycleState;
      return ls == AppLifecycleState.paused || ls == AppLifecycleState.hidden;
    } on Object {
      return false;
    }
  }

  /// Levanta el foreground service (con su notificación) si no corre ya. Tolera
  /// la restricción de Android 12+ de iniciar un FGS desde segundo plano: si el
  /// SO lo rechaza, el rastreo sigue en primer plano y reintenta al próximo paso.
  ///
  /// La notificación del servicio usa el id de la ruta en vivo y un texto
  /// NEUTRO: al quedar arriba ([TruckTrackingState.foregroundServiceRunning])
  /// la ruta en vivo vuelve a publicar su contenido con ese id, así queda una
  /// sola notificación. El texto neutro solo se ve si no hay ruta (raro) o si
  /// el sistema reinicia el servicio sin la app (no se usa el estado de la
  /// ruta acá: quedaría viejo en ese caso).
  Future<void> _startForegroundService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        _setServiceRunning(true);
        return;
      }
      _ensureChannel();
      final permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      final result = await FlutterForegroundTask.startService(
        serviceId: routeLiveNotificationId,
        notificationTitle: routeLiveFallbackTitle,
        notificationText: routeLiveFallbackText,
      );
      _setServiceRunning(result is ServiceRequestSuccess);
    } on Object {
      // SO rechazó el FGS (p. ej. background-start restringido): no es crítico.
    }
  }

  /// Baja el foreground service (oculta la notificación) si está corriendo.
  Future<void> _stopForegroundService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } on Object {
      // Sin plugin (tests) o error del SO: no es crítico.
    }
    _setServiceRunning(false);
  }

  /// Publica si el foreground service quedó arriba (la ruta en vivo lo escucha).
  void _setServiceRunning(bool running) {
    if (!ref.mounted || state.foregroundServiceRunning == running) return;
    state = state.copyWith(foregroundServiceRunning: running);
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
        // SIN Wi-Fi lock: mantenía la Wi-Fi en modo de alto rendimiento todo
        // el turno. El chofer va con datos móviles; los envíos por lote no lo
        // necesitan.
        allowWifiLock: false,
      ),
    );
    _channelReady = true;
  }

  /// Inicia (o re-apunta) el rastreo del envío [shipmentId]. Se suscribe al
  /// stream de GPS (el foreground service se levanta solo en segundo plano).
  /// Devuelve `false` si falta el permiso de ubicación "siempre".
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
      if (_shipmentId != shipmentId) {
        // Cambio de parada: lo juntado del envío anterior sale ya.
        unawaited(_flush());
      }
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

    final current = _pendingShipmentId ?? shipmentId;
    _pendingShipmentId = null;
    _shipmentId = current;
    _lastEnqueuedAt = null;
    _lastEnqueuedFix = null;
    _firstFixSent = false;
    _lastFlushAt = null;
    _motion.reset();
    _profile = TrackingProfile.resolve(
      motion: TruckMotion.moving,
      saveEnergy: _saveEnergy,
    );
    // Nunca dos suscripciones al GPS a la vez. En primer plano alcanza el stream
    // directo (sin servicio ni notificación); el foreground service se levanta
    // solo al pasar a segundo plano (ver [_onLifecycleChange]).
    await _subscribe();
    state = TruckTrackingState(
      active: true,
      shipmentId: current,
      sent: 0,
      lastFix: null,
      foregroundServiceRunning: state.foregroundServiceRunning,
    );
    // Si al arrancar el rastreo la app YA está en segundo plano, se levanta el
    // servicio enseguida para no perder posiciones.
    if (_isBackground) unawaited(_startForegroundService());
    return true;
  }

  /// `true` si el teléfono está en ahorro de energía o con batería baja.
  bool get _saveEnergy {
    try {
      return ref.read(powerStatusProvider).shouldSaveEnergy;
    } on Object {
      return false;
    }
  }

  /// (Re)suscribe el GPS con el perfil vigente (cancelando el anterior).
  Future<void> _subscribe() async {
    await _sub?.cancel();
    _sub = ref
        .read(locationServiceProvider)
        .stream(profile: _profile)
        .listen(_onFix);
  }

  /// Recalcula el perfil (movimiento + energía) y, si cambió, re-suscribe el
  /// GPS con los ajustes nuevos. Sin rastreo activo no hace nada.
  void _applyProfile() {
    if (!state.active && _starting == null) return;
    final next = TrackingProfile.resolve(
      motion: _motion.motion,
      saveEnergy: _saveEnergy,
    );
    if (identical(next, _profile)) return;
    _profile = next;
    if (_sub != null) unawaited(_subscribe());
    _armHeartbeat();
  }

  /// Detiene el rastreo y baja el foreground service. Lo juntado en el lote se
  /// encola antes de soltar el envío.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _flush();
    _cancelTimers();
    _shipmentId = null;
    try {
      await FlutterForegroundTask.stopService();
    } on Object {
      // Sin plugin (tests) o error del SO: no es crítico.
    }
    state = state.copyWith(active: false, foregroundServiceRunning: false);
  }

  /// Baja un foreground service HUÉRFANO: uno que sobrevivió a un cierre de la
  /// app o a un cambio de rol y dejó colgada su notificación (id 4120)
  /// aunque el usuario ya no sea un chofer rastreándose. Seguro de llamar
  /// siempre (al arrancar): `stopService` no hace nada si no hay servicio
  /// corriendo, y si el usuario ES chofer con parada activa el autostart lo
  /// vuelve a levantar. No depende del estado en memoria (que tras un reinicio
  /// está limpio aunque el servicio siga vivo).
  Future<void> stopOrphanedService() async {
    try {
      await FlutterForegroundTask.stopService();
    } on Object {
      // Sin plugin (tests) o error del SO: no es crítico.
    }
    if (state.active || state.foregroundServiceRunning) {
      state = state.copyWith(active: false, foregroundServiceRunning: false);
    }
  }

  /// Procesa una lectura del GPS: actualiza en marcha/detenido (y el perfil),
  /// descarta lecturas demasiado seguidas o en el mismo lugar, y junta la
  /// posición en el lote. Mismo contrato de siempre al encolar: kind
  /// `ingestTruckPosition` + `@shipmentId` (offline-first, nunca espera a la
  /// red).
  void _onFix(GpsFix fix) {
    final shipmentId = _shipmentId;
    if (shipmentId == null) return;
    final now = clock();
    if (_motion.onFix(fix, now)) _applyProfile();
    _armStillTimer(now);

    final last = _lastEnqueuedAt;
    final lastFix = _lastEnqueuedFix;
    // Lecturas demasiado seguidas se descartan: ni fila, ni POST, ni rebuild.
    if (last != null && now.difference(last) < _profile.minEnqueueInterval) {
      _maybeFlushOverdue(now);
      return;
    }
    // Mismo lugar (jitter): solo se reenvía como latido.
    if (lastFix != null &&
        last != null &&
        MotionDetector.distanceMeters(lastFix, fix) < minEnqueueMeters &&
        now.difference(last) < _profile.heartbeatInterval) {
      _maybeFlushOverdue(now);
      return;
    }
    _collect(shipmentId, fix, now);
  }

  /// Junta una posición en el lote y decide si se envía ya.
  void _collect(String shipmentId, GpsFix fix, DateTime now) {
    _lastEnqueuedAt = now;
    _lastEnqueuedFix = fix;
    state = state.copyWith(lastFix: fix);
    _batch.add((shipmentId: shipmentId, fix: fix, at: now));
    _armHeartbeat();
    // La primera posición de cada arranque sale enseguida: el supervisor ve el
    // camión apenas empieza la ruta.
    if (!_firstFixSent || _batch.length >= maxBatch) {
      _firstFixSent = true;
      unawaited(_flush());
      return;
    }
    if (!_maybeFlushOverdue(now)) {
      _flushTimer ??= Timer(_profile.flushInterval, () {
        _flushTimer = null;
        unawaited(_flush());
      });
    }
  }

  /// Envía el lote si el último envío fue hace más de un intervalo (por si el
  /// timer se atrasó con la CPU dormida). Devuelve `true` si envió.
  bool _maybeFlushOverdue(DateTime now) {
    if (_batch.isEmpty) return false;
    final at = _lastFlushAt;
    if (at != null && now.difference(at) < _profile.flushInterval) {
      return false;
    }
    unawaited(_flush());
    return true;
  }

  /// Encola (en ráfaga, en orden) las posiciones juntadas. La cola offline las
  /// intenta enviar enseguida: así todos los POST salen juntos y la radio
  /// vuelve a dormir. Nunca lanza.
  Future<void> _flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_batch.isEmpty) return;
    final items = List<_PendingFix>.of(_batch);
    _batch.clear();
    _lastFlushAt = clock();
    final queue = ref.read(offlineQueueProvider);
    for (final item in items) {
      final payload = <String, Object?>{
        ...TruckPositionInput(
          lat: item.fix.lat,
          lng: item.fix.lng,
          reportedAt: item.at,
        ).toJson(),
        '@shipmentId': item.shipmentId,
      };
      try {
        await queue.submit(
          kind: 'ingestTruckPosition',
          payload: payload,
          label: 'GPS · ${item.shipmentId}',
          occurredAt: item.at,
        );
        if (ref.mounted) state = state.copyWith(sent: state.sent + 1);
      } on Object {
        // Error de la base local: se pierde solo esta posición (telemetría).
      }
    }
    // Aprovecha el envío para seguir la batería durante la ruta.
    if (ref.mounted) {
      try {
        unawaited(ref.read(powerStatusProvider.notifier).refreshIfStale());
      } on Object {
        // Sin canal de energía: comportamiento normal.
      }
    }
  }

  /// (Re)arma el chequeo de "detenido" para cuando se cumpla el tiempo sin
  /// moverse (con el filtro de distancia, quieto no llegan lecturas).
  void _armStillTimer(DateTime now) {
    _stillTimer?.cancel();
    _stillTimer = null;
    final left = _motion.timeUntilStill(now);
    if (left == null) return;
    _stillTimer = Timer(left, checkStillness);
  }

  /// Revisa si el camión ya está detenido y ajusta el perfil. Lo llama el
  /// timer; expuesto para tests.
  @visibleForTesting
  void checkStillness() {
    _stillTimer = null;
    if (_motion.evaluate(clock())) _applyProfile();
  }

  /// Con el camión detenido no llegan lecturas (filtro de distancia): cada
  /// [TrackingProfile.heartbeatInterval] se reenvía la última posición para
  /// que el supervisor lo siga viendo activo.
  void _armHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (!state.active || _motion.motion != TruckMotion.stationary) return;
    _heartbeatTimer = Timer(_profile.heartbeatInterval, heartbeat);
  }

  /// Reenvía la última posición como latido (expuesto para tests).
  @visibleForTesting
  void heartbeat() {
    _heartbeatTimer = null;
    final shipmentId = _shipmentId;
    final fix = _lastEnqueuedFix;
    if (shipmentId == null || fix == null || !state.active) return;
    _collect(shipmentId, fix, clock());
    unawaited(_flush());
  }

  /// Envía ya el lote pendiente (tests).
  @visibleForTesting
  Future<void> flushNow() => _flush();

  /// Posiciones juntadas a la espera del envío (tests).
  @visibleForTesting
  int get pendingBatch => _batch.length;

  void _cancelTimers() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _stillTimer?.cancel();
    _stillTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}

final truckTrackingProvider =
    NotifierProvider<TruckTrackingService, TruckTrackingState>(
      TruckTrackingService.new,
    );
