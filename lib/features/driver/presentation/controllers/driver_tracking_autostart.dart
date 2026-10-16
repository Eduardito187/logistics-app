import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/location/truck_tracking_service.dart';
import 'driver_controllers.dart';

/// Envío al que debe asociarse el rastreo automático del camión: la parada en
/// curso de la ruta del día, o la primera pendiente si no hay una marcada en
/// curso. Devuelve `null` cuando no hay ruta/parada activa (ruta completada, sin
/// paradas o aún cargando), que es la señal para detener el rastreo.
final activeTrackingShipmentIdProvider = Provider.autoDispose<String?>((ref) {
  final route = ref.watch(driverRouteProvider).asData?.value;
  if (route == null) return null;
  if (route.status == DriverRouteStatus.completed) return null;

  final current = route.currentStop;
  if (current != null && current.status == DriverRouteStopStatus.pending) {
    return current.shipmentId;
  }
  for (final stop in route.stops) {
    if (stop.status == DriverRouteStopStatus.pending) return stop.shipmentId;
  }
  return null;
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
  ProviderSubscription<String?>? _subscription;

  @override
  void initState() {
    super.initState();
    // `fireImmediately` aplica el efecto también con el valor inicial, así el
    // rastreo arranca apenas se monta el gate si ya hay parada activa.
    _subscription = ref.listenManual<String?>(
      activeTrackingShipmentIdProvider,
      (previous, next) {
        final tracking = ref.read(truckTrackingProvider.notifier);
        if (next != null) {
          unawaited(tracking.start(shipmentId: next));
        } else {
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
