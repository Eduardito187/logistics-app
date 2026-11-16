import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../domain/usecases/list_vehicle_checklists.dart';
import 'driver_controllers.dart';

/// Historial de inspecciones diarias (checklists pre-salida) de un vehículo,
/// más reciente primero. Family por `vehicleId` (el gate del chofer lo provee).
final inspectionHistoryProvider = FutureProvider.autoDispose
    .family<List<PreTripChecklist>, String>((ref, vehicleId) {
      return ref
          .watch(listVehicleChecklistsProvider)
          .call(vehicleId: vehicleId);
    });

/// ¿Falta la inspección pre-salida de la ruta/salida EN CURSO? El chofer no debe
/// empezar a entregar sin haber hecho el checklist del camión de esa salida.
///
/// Combina el historial de inspecciones del vehículo asignado con la ruta del
/// día (su `route_id`), reusando [inspectionForCurrentRoute] (modo por ruta o,
/// con backend viejo, diario).
///
/// Es **fail-open**: mientras no se SEPA (sin vehículo, historial cargando o en
/// error, o en modo por ruta todavía sin ruta ligable) devuelve `false` y no
/// bloquea. El checklist se hace con señal antes de salir; trabar al chofer por
/// una lectura que no llegó sería peor (offline invisible). Solo devuelve `true`
/// cuando el historial llegó y confirma que la inspección de esta salida falta.
final preTripChecklistPendingProvider = Provider.autoDispose<bool>((ref) {
  final vehicleId = ref.watch(assignedVehicleIdProvider);
  if (vehicleId == null) return false;
  final routeId = ref.watch(driverRouteProvider).value?.id;
  final checklists = ref.watch(inspectionHistoryProvider(vehicleId)).value;
  if (checklists == null) return false;
  // En modo por ruta sin ruta todavía no se puede ligar la inspección: no se
  // bloquea (no hay salida que iniciar sin ruta).
  if (perRouteChecklistMode(checklists) && routeId == null) return false;
  return inspectionForCurrentRoute(checklists, routeId, DateTime.now()) == null;
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
    if (best == null ||
        (at != null && (bestAt == null || at.isAfter(bestAt)))) {
      best = c;
      bestAt = at;
    }
  }
  return best;
}
