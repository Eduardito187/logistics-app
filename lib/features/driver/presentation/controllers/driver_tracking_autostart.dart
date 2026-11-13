import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/location/truck_tracking_service.dart';
import '../widgets/route_points.dart';
import 'driver_controllers.dart';
import 'locally_settled_stops.dart';

/// Envío al que debe asociarse el rastreo automático del camión: la parada en
/// curso de la ruta del día, o la primera pendiente si no hay una marcada en
/// curso (sin contar las ya resueltas en este teléfono). Si ya no quedan
/// pendientes, se sigue rastreando el ÚLTIMO envío (regreso al CD). Devuelve
/// `null` solo cuando no hay ruta todavía o la ruta no tiene paradas.
///
/// `.value` (no `.asData?.value`): mientras la ruta se refresca (cada
/// `invalidate` al volver de un POD) conserva la ruta anterior; con `asData`
/// pasaba a `null` un instante y el rastreo se apagaba y volvía a prender
/// (servicio en primer plano + GPS: el camión desaparecía del mapa ~10 s).
final activeTrackingShipmentIdProvider = Provider.autoDispose<String?>((ref) {
  final route = ref.watch(driverRouteProvider).value;
  if (route == null) return null;
  return _shipmentToTrack(route, ref.watch(locallySettledStopsProvider));
});

String? _shipmentToTrack(
  DriverRoute route,
  Map<String, DriverRouteStopStatus> settled,
) {
  // Mientras haya una parada pendiente, se rastrea ESA.
  final pending = pendingStopOf(route, settled)?.shipmentId;
  if (pending != null) return pending;
  // Sin pendientes (ruta "completada"): el camión SIGUE rastreándose en el
  // regreso al centro de distribución hasta que el chofer cierre sesión o le den
  // descanso (el logout lo detiene desde el propio servicio). Se asocia al
  // ÚLTIMO envío de la ruta para que los breadcrumbs sigan fluyendo: el backend
  // los agrupa por envío, y el seguimiento del regreso a nivel ruta es un
  // pendiente del backend (ver pedido de re-ruteo/regreso).
  final stops = sortedStops(route);
  return stops.isEmpty ? null : stops.last.shipmentId;
}

/// Decisión del rastreo: `known == false` mientras todavía no hay NINGUNA ruta
/// (primera carga o primera carga fallida sin señal); en ese caso no se toca el
/// rastreo (ni se apaga uno ya activo). Con ruta, el envío a rastrear o `null`
/// para detenerlo. Es un record: solo notifica cuando cambia de verdad.
final trackingDecisionProvider =
    Provider.autoDispose<({bool known, String? shipmentId})>((ref) {
      final route = ref.watch(driverRouteProvider).value;
      if (route == null) return (known: false, shipmentId: null);
      return (
        known: true,
        shipmentId: _shipmentToTrack(
          route,
          ref.watch(locallySettledStopsProvider),
        ),
      );
    });

/// Efecto que arranca y detiene el rastreo del camión de forma AUTOMÁTICA, sin
/// botón: en cuanto el chofer tiene vehículo + una parada activa, se inicia el
/// [TruckTrackingService] con el `shipmentId` de esa parada; cuando la ruta se
/// completa (o deja de haber parada activa) se detiene. El cierre de sesión lo
/// detiene aparte, desde el propio servicio (sobrevive a la navegación).
///
/// Se monta dentro del gate del chofer (`DriverVehicleGate`), que sólo construye
/// su contenido cuando hay vehículo y el permiso de ubicación "siempre" ya está
/// concedido; por eso `start` no debería fallar por permisos acá.
class DriverTrackingAutostart extends ConsumerStatefulWidget {
  const DriverTrackingAutostart({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DriverTrackingAutostart> createState() =>
      _DriverTrackingAutostartState();
}

class _DriverTrackingAutostartState
    extends ConsumerState<DriverTrackingAutostart> {
  ProviderSubscription<({bool known, String? shipmentId})>? _subscription;

  @override
  void initState() {
    super.initState();
    // `fireImmediately` aplica el efecto también con el valor inicial, así el
    // rastreo arranca apenas se monta el gate si ya hay parada activa.
    _subscription = ref.listenManual<({bool known, String? shipmentId})>(
      trackingDecisionProvider,
      (previous, next) {
        // Sin ruta todavía: no se decide nada (no apagar por "cargando").
        if (!next.known) return;
        // Mismo envío que antes: nada que hacer (no reiniciar el servicio).
        if (previous != null &&
            previous.known &&
            previous.shipmentId == next.shipmentId) {
          return;
        }
        final tracking = ref.read(truckTrackingProvider.notifier);
        final current = ref.read(truckTrackingProvider);
        final shipmentId = next.shipmentId;
        if (shipmentId != null) {
          // Al montar el gate de otra pantalla con el rastreo ya andando para
          // el mismo envío, no se vuelve a llamar a `start`.
          if (current.active && current.shipmentId == shipmentId) return;
          unawaited(tracking.start(shipmentId: shipmentId));
        } else {
          // Sin filtrar por `active`: el servicio pudo sobrevivir a un reinicio
          // de la app con el estado en memoria ya limpio.
          unawaited(tracking.stop());
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
