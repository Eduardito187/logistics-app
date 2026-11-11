import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../domain/usecases/list_vehicle_checklists.dart';

/// Historial de inspecciones diarias (checklists pre-salida) de un vehículo,
/// más reciente primero. Family por `vehicleId` (el gate del chofer lo provee).
final inspectionHistoryProvider = FutureProvider.autoDispose
    .family<List<PreTripChecklist>, String>((ref, vehicleId) {
      return ref
          .watch(listVehicleChecklistsProvider)
          .call(vehicleId: vehicleId);
    });

/// True si la inspección más reciente de [checklists] se hizo HOY (mismo día que
/// [now] en zona local). La lista se asume ordenada DESC por `performedOn`, pero
/// no se confía en ello: se busca cualquier inspección de hoy. Lista vacía o sin
/// fecha → false.
bool inspectionDoneToday(List<PreTripChecklist> checklists, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  for (final c in checklists) {
    final performed = c.performedOn;
    if (performed == null) continue;
    final local = performed.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return true;
  }
  return false;
}
