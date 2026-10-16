import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/widgets/async_value_view.dart';
import 'controllers/driver_controllers.dart';
import 'driver_vehicle_gate.dart';
import 'widgets/tracking_status_body.dart';

/// Estado del rastreo GPS del camión. El rastreo es AUTOMÁTICO y OBLIGATORIO:
/// arranca solo al tener una parada activa y corre en un foreground service para
/// seguir enviando con la app minimizada. Esta pantalla NO enciende ni apaga
/// nada; sólo informa que está activo, cuántas posiciones se enviaron y la
/// última posición conocida.
class LiveGpsScreen extends ConsumerWidget {
  const LiveGpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DriverVehicleGate(
      title: 'Rastreo del camión',
      builder: (context, vehicleId) {
        final route = ref.watch(driverRouteProvider);
        return AsyncValueView<DriverRoute>(
          value: route,
          onRetry: () => ref.invalidate(driverRouteProvider),
          data: (data) {
            final target =
                data.currentStop ??
                _firstPending(data.stops) ??
                (data.stops.isEmpty ? null : data.stops.first);
            return TrackingStatusBody(target: target);
          },
        );
      },
    );
  }

  DriverRouteStop? _firstPending(List<DriverRouteStop> stops) {
    for (final stop in stops) {
      if (stop.status == DriverRouteStopStatus.pending) return stop;
    }
    return null;
  }
}
