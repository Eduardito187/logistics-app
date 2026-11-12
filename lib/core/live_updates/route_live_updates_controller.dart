import 'dart:async';

import 'live_updates_service.dart';
import 'route_island.dart';
import 'route_live_state.dart';
import 'route_live_status.dart';

/// Decide CUÁNDO publicar la ruta del chofer en la notificación en vivo.
///
/// Recibe una foto nueva con cada cambio de la ruta o fix del GPS
/// ([onStatus]) y llama al canal nativo SOLO si cambió algo que se ve:
/// - Arranca (`start`) apenas hay una parada activa.
/// - Cambio de parada, de estado, de avance, de cliente o de ETA → `update`
///   al instante.
/// - Solo la distancia ("2,3 km" → "2,1 km") → como máximo una vez cada
///   [minUpdateInterval] (la batería es crítica: el GPS emite seguido y cada
///   update despierta al sistema de notificaciones / ActivityKit).
/// - Igual a lo último publicado → nada.
/// - Ruta terminada o sin ruta/sesión → `end`.
///
/// "Entregando": si el camión sigue dentro de la geocerca de llegada durante
/// [dwellThreshold], el estado pasa de "Llegaste" a "Entregando".
///
/// [hideInForeground] (Android): con la app abierta la notificación se quita
/// (decisión del dueño: nada de notificaciones con la app en pantalla; además
/// Android oculta el chip de la app en primer plano) y vuelve al pasar a
/// segundo plano. En iOS va en `false`: la Live Activity solo se puede pedir
/// con la app en primer plano y el sistema ya la oculta de la isla mientras la
/// app está en pantalla.
///
/// Foreground service del rastreo ([setServiceRunning], Android): comparte el
/// id de notificación con la ruta en vivo (`routeLiveNotificationId`), así
/// queda UNA sola notificación. Al arrancar, el plugin postea su texto neutro
/// con ese id → acá se vuelve a publicar la última foto encima (una vez). Con
/// el servicio corriendo la notificación NO se quita (cancelarla no tiene
/// efecto sobre la de un foreground service). Al bajar el servicio, Android
/// se lleva la notificación con él.
///
/// Isla ([setIslandMode], Android): con [RouteIslandMode.overlay] además de la
/// notificación se muestra la isla de DisTrack (pastilla flotante) SOLO con la
/// app en segundo plano, con las mismas fotos y el mismo throttling que la
/// notificación; y la notificación va sin pedido de promoción (una sola isla).
///
/// Sin timers propios: un cambio menor que llega antes del intervalo se
/// publica con la siguiente foto que lo permita.
class RouteLiveUpdatesController {
  RouteLiveUpdatesController({
    required LiveUpdatesService service,
    this.hideInForeground = false,
    bool foreground = true,
    DateTime Function()? clock,
    this.minUpdateInterval = const Duration(seconds: 30),
    this.dwellThreshold = const Duration(seconds: 90),
    this.onArrived,
  }) : _service = service,
       _foreground = foreground,
       _clock = clock ?? DateTime.now;

  final LiveUpdatesService _service;
  final DateTime Function() _clock;

  /// Quitar la notificación mientras la app está en primer plano (Android).
  final bool hideInForeground;

  /// Intervalo mínimo entre updates que solo cambian la distancia.
  final Duration minUpdateInterval;

  /// Tiempo dentro de la geocerca para pasar a "Entregando".
  final Duration dwellThreshold;

  /// Distancia a la parada a partir de la cual, ya llegado, se considera que
  /// se fue (histéresis de la geocerca de 60 m).
  static const double leaveArrivalMeters = 120;

  /// Aviso (vibración) al entrar en la geocerca de una parada, una vez por
  /// parada. Lo usa el provider para vibrar si la app está en pantalla.
  final void Function()? onArrived;

  bool _foreground;
  bool _serviceRunning = false;
  RouteIslandMode _islandMode = RouteIslandMode.none;
  bool _overlayShown = false;
  bool _shown = false;
  bool _cleared = false;
  bool _disposed = false;

  /// Última foto recibida (ya con el estado "Entregando" aplicado).
  RouteLiveStatus? _latest;

  /// Última foto publicada en el nativo y cuándo.
  RouteLiveStatus? _lastSent;
  DateTime? _lastSentAt;

  /// Desde cuándo está dentro de la geocerca de [_dwellStopId].
  DateTime? _arrivedSince;
  String? _dwellStopId;

  /// Parada para la que ya se avisó la llegada.
  String? _arrivalNotifiedStopId;

  /// ¿Hay una notificación / Live Activity mostrada ahora?
  bool get isShown => _shown;

  /// Última foto publicada (para tests y diagnóstico).
  RouteLiveStatus? get lastSent => _lastSent;

  /// ¿El foreground service del rastreo está arriba? (su notificación ES la
  /// de la ruta en vivo).
  bool get serviceRunning => _serviceRunning;

  /// Isla vigente (Android).
  RouteIslandMode get islandMode => _islandMode;

  /// ¿Está la isla de DisTrack en pantalla?
  bool get isOverlayShown => _overlayShown;

  bool get _overlayAllowed =>
      hideInForeground &&
      !_foreground &&
      _islandMode == RouteIslandMode.overlay;

  bool get _hidden => hideInForeground && _foreground && !_serviceRunning;

  /// Nueva foto de la ruta (`null` = no hay ruta activa, no es chofer o se
  /// cerró la sesión).
  void onStatus(RouteLiveStatus? incoming) {
    if (_disposed) return;
    final now = _clock();
    if (incoming == null) {
      _latest = null;
      _resetDwell();
      _syncOverlay(null);
      // La primera vez se limpia igual: una notificación huérfana de una
      // ejecución anterior (proceso matado) no debe quedar colgada.
      if (_shown || !_cleared) _end();
      return;
    }

    final status = _applyDwell(incoming, now);
    _notifyArrival(status);
    _latest = status;
    if (_hidden) return;
    _publish(status, now);
  }

  /// La app pasó a primer plano ([foreground] `true`) o a segundo plano.
  void setForeground(bool foreground) {
    if (_disposed || _foreground == foreground) return;
    _foreground = foreground;
    if (!hideInForeground) return;
    if (foreground) {
      // La isla de DisTrack nunca tapa la propia app.
      _syncOverlay(null);
      // Con el foreground service arriba la notificación es la del servicio:
      // se mantiene (se va sola cuando el rastreo baja el servicio).
      if (_shown && !_serviceRunning) _end();
      return;
    }
    final latest = _latest;
    if (latest != null) _publish(latest, _clock());
    // La notificación pudo no cambiar (ya estaba): la isla igual aparece.
    if (!_overlayShown) _syncOverlay(_latest);
  }

  /// Cambia la isla (la decide `routeIslandModeProvider`: disponibilidad +
  /// preferencia). Pasar a/desde la isla de DisTrack enciende o apaga el pedido
  /// de promoción del sistema; si la notificación ya está, se re-publica para
  /// que el chip del sistema aparezca o se vaya.
  void setIslandMode(RouteIslandMode mode) {
    if (_disposed || mode == _islandMode) return;
    final wasOverlay = _islandMode == RouteIslandMode.overlay;
    _islandMode = mode;
    final isOverlay = mode == RouteIslandMode.overlay;
    if (wasOverlay != isOverlay) {
      unawaited(_service.setPromotionEnabled(!isOverlay));
      final last = _lastSent;
      if (_shown && last != null) _send(last, _clock(), start: false);
    }
    _syncOverlay(_latest);
  }

  /// El foreground service del rastreo subió ([running] `true`) o bajó.
  ///
  /// - Subió: el plugin acaba de postear su texto neutro con el id compartido
  ///   → se re-publica la última foto (aunque sea igual a la enviada).
  /// - Bajó: Android se llevó la notificación con el servicio. En segundo
  ///   plano se vuelve a mostrar la ruta (como notificación normal); en primer
  ///   plano queda oculta (regla de [hideInForeground]).
  void setServiceRunning(bool running) {
    if (_disposed || _serviceRunning == running) return;
    _serviceRunning = running;
    final now = _clock();
    final latest = _latest;
    if (running) {
      if (latest == null || latest.state == RouteLiveState.finished) return;
      _send(latest, now, start: !_shown);
      return;
    }
    if (_hidden) {
      if (_shown) _end();
      return;
    }
    _shown = false;
    _lastSentAt = null;
    if (latest != null) _publish(latest, now);
  }

  /// Cierre (logout / dispose del provider): quita lo mostrado.
  void dispose() {
    if (_disposed) return;
    if (_shown) _end();
    _syncOverlay(null);
    _disposed = true;
  }

  void _publish(RouteLiveStatus status, DateTime now) {
    if (status.state == RouteLiveState.finished) {
      if (_shown) _end(status);
      _syncOverlay(null);
      _lastSent = status;
      return;
    }
    final last = _lastSent;
    if (!_shown) {
      _send(status, now, start: true);
      return;
    }
    if (last != null && status.sameContentAs(last)) return;
    final major = last == null || status.majorChangeFrom(last);
    final lastAt = _lastSentAt;
    final due = lastAt == null || now.difference(lastAt) >= minUpdateInterval;
    if (major || due) _send(status, now, start: false);
  }

  void _send(RouteLiveStatus status, DateTime now, {required bool start}) {
    _shown = true;
    _cleared = false;
    _lastSent = status;
    _lastSentAt = now;
    unawaited(start ? _service.start(status) : _service.update(status));
    _syncOverlay(status);
  }

  /// Muestra / actualiza la isla de DisTrack con [status], o la quita si no
  /// corresponde (primer plano, otra isla, sin ruta o ruta terminada).
  void _syncOverlay(RouteLiveStatus? status) {
    final show =
        _overlayAllowed &&
        status != null &&
        status.state != RouteLiveState.finished;
    if (show) {
      _overlayShown = true;
      unawaited(_service.showOverlay(status));
    } else if (_overlayShown) {
      _overlayShown = false;
      unawaited(_service.hideOverlay());
    }
  }

  void _end([RouteLiveStatus? last]) {
    _shown = false;
    _cleared = true;
    _lastSentAt = null;
    unawaited(_service.end(last));
    _syncOverlay(null);
  }

  /// "Llegaste" sostenido [dwellThreshold] en la misma parada → "Entregando".
  ///
  /// Con histéresis: una vez dentro, el ruido del GPS que lo "saca" unos metros
  /// (hasta [leaveArrivalMeters]) no lo devuelve a "En camino" (si no, la
  /// notificación parpadearía entre los dos estados en el borde de la geocerca).
  RouteLiveStatus _applyDwell(RouteLiveStatus incoming, DateTime now) {
    var status = incoming;
    final meters = incoming.remainingMeters;
    if (incoming.state == RouteLiveState.onTheWay &&
        _dwellStopId == incoming.stopId &&
        _arrivedSince != null &&
        meters != null &&
        meters <= leaveArrivalMeters) {
      status = incoming.copyWith(state: RouteLiveState.arriving);
    }
    if (status.state != RouteLiveState.arriving) {
      _resetDwell();
      return status;
    }
    if (_dwellStopId != status.stopId || _arrivedSince == null) {
      _dwellStopId = status.stopId;
      _arrivedSince = now;
      return status;
    }
    return now.difference(_arrivedSince!) >= dwellThreshold
        ? status.copyWith(state: RouteLiveState.delivering)
        : status;
  }

  void _resetDwell() {
    _arrivedSince = null;
    _dwellStopId = null;
  }

  void _notifyArrival(RouteLiveStatus status) {
    final arrived =
        status.state == RouteLiveState.arriving ||
        status.state == RouteLiveState.delivering;
    if (!arrived || _arrivalNotifiedStopId == status.stopId) return;
    _arrivalNotifiedStopId = status.stopId;
    onArrived?.call();
  }
}
