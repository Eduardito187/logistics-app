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

/// Modo "checklist POR RUTA" activo: el backend ya etiqueta las inspecciones con
/// `route_id` (algún item lo trae). Mientras el backend viejo no lo mande, se cae
/// al criterio DIARIO para no regresionar. Así la app se auto-actualiza al
/// comportamiento por ruta en cuanto el backend empieza a etiquetar, sin tocar
/// código. Ver docs/backend-requests/2026-11-13-checklist-por-ruta-y-placa.md.
bool perRouteChecklistMode(List<PreTripChecklist> checklists) =>
    checklists.any((c) => c.routeId != null);

/// La inspección que da por "cumplido" el checklist para la salida actual, o
/// `null` si falta (→ hay que mostrar el formulario).
///
/// - En modo POR RUTA: el checklist ligado a [currentRouteId] (el más reciente si
///   hubiera varios). Sin ruta en curso → `null` (no se puede ligar todavía).
/// - En modo DIARIO (backend viejo): la inspección de HOY más reciente.
PreTripChecklist? inspectionForCurrentRoute(
  List<PreTripChecklist> checklists,
  String? currentRouteId,
  DateTime now,
) {
  final perRoute = perRouteChecklistMode(checklists);
  final today = DateTime(now.year, now.month, now.day);
  PreTripChecklist? best;
  DateTime? bestAt;
  for (final c in checklists) {
    final bool matches;
    if (perRoute) {
      matches = currentRouteId != null && c.routeId == currentRouteId;
    } else {
      final performed = c.performedOn?.toLocal();
      matches =
          performed != null &&
          DateTime(performed.year, performed.month, performed.day) == today;
    }
    if (!matches) continue;
    final at = c.performedOn?.toLocal();
    if (best == null || (at != null && (bestAt == null || at.isAfter(bestAt)))) {
      best = c;
      bestAt = at;
    }
  }
  return best;
}
