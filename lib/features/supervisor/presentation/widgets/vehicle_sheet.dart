import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/api/models/vehicle_telemetry_summary.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/supervisor_controllers.dart';
import '../supervisor_labels.dart';

/// Hoja inferior con el detalle de un camión y su resumen de telemetría del día.
class VehicleSheet extends ConsumerWidget {
  const VehicleSheet({super.key, required this.vehicle});

  final VehicleLive vehicle;

  /// Abre la hoja inferior para [vehicle].
  static Future<void> show(BuildContext context, VehicleLive vehicle) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => VehicleSheet(vehicle: vehicle),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(vehicleSummaryProvider(vehicle.vehicleId));
    final speed = vehicle.speedKph;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Camión ${vehicle.vehicleId}',
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusPill(
                vehicle.moving ? 'En movimiento' : 'Detenido',
                tone: vehicle.moving ? PillTone.success : PillTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Última lectura: ${formatHour(vehicle.recordedAt)}'),
          if (speed != null) Text('Velocidad: ${speed.round()} km/h'),
          const SizedBox(height: 16),
          AsyncValueView<VehicleTelemetrySummary>(
            value: summary,
            onRetry: () =>
                ref.invalidate(vehicleSummaryProvider(vehicle.vehicleId)),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del día',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Distancia: ${(data.distanceM / 1000).toStringAsFixed(1)} km',
                ),
                Text('Viajes: ${data.trips}'),
                Text('Velocidad máx: ${data.maxSpeedKph.round()} km/h'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
