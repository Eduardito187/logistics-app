import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/driver_controllers.dart';
import 'daily_inspection_reminder.dart';

/// Recordatorio de la inspección diaria para el INICIO del chofer. Resuelve el
/// camión asignado (`assignedVehicleIdProvider`, derivado del crew) y, si hay
/// vehículo, delega en [DailyInspectionReminder] (que a su vez solo se muestra
/// si hoy falta la inspección). Sin vehículo asignado todavía → no ocupa
/// espacio. Encapsula la dependencia del home con el feature del chofer.
class DriverHomeInspectionReminder extends ConsumerWidget {
  const DriverHomeInspectionReminder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleId = ref.watch(assignedVehicleIdProvider);
    if (vehicleId == null) return const SizedBox.shrink();
    return DailyInspectionReminder(
      vehicleId: vehicleId,
      onTap: () => context.push('/driver/checklist'),
    );
  }
}
