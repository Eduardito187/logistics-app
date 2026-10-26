import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/section_card.dart';
import 'controllers/driver_controllers.dart';
import 'driver_vehicle_gate.dart';
import 'widgets/cost_grid.dart';
import 'widgets/utilization_card.dart';

/// Resumen del vehículo (estilo "finanzas" de los mockups): costos (TCO,
/// costo/km) y utilización de los últimos 30 días usando fleetOps.
class VehicleSummaryScreen extends ConsumerWidget {
  const VehicleSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DriverVehicleGate(
      title: 'Resumen del vehículo',
      builder: (context, vehicleId) {
        final cost = ref.watch(vehicleCostSummaryProvider);
        return ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'Costos (últimos 30 días)',
                child: AsyncValueView<VehicleCostSummary>(
                  value: cost,
                  onRetry: () => ref.invalidate(vehicleCostSummaryProvider),
                  data: CostGrid.new,
                ),
              ),
              const SizedBox(height: 16),
              const UtilizationCard(),
            ],
          ),
        );
      },
    );
  }
}
