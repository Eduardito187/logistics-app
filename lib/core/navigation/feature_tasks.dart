import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/carrier/presentation/carrier_routes.dart';
import '../../features/driver/presentation/driver_routes.dart';
import '../../features/picking/presentation/picking_routes.dart';
import '../../features/settings/presentation/settings_routes.dart';
import '../../features/store/presentation/store_routes.dart';
import '../../features/supervisor/presentation/supervisor_routes.dart';
import '../auth/session.dart';
import 'role_task.dart';

/// Todas las tarjetas de acción, aportadas por cada feature. El inicio del rol
/// filtra por `RoleTask.roles`. App de campo: entregas y despacho (chofer,
/// preparador, tienda, transportista, supervisor). Las vistas de oficina/admin
/// viven en el admin del backend (Filament + SPA), no acá.
final featureTasksProvider = Provider<List<RoleTask>>((ref) {
  return [
    ...pickingTasks,
    ...driverTasks,
    ...storeTasks,
    ...carrierTasks,
    ...supervisorTasks,
    ...settingsTasks,
  ];
});

/// Filtra las tareas visibles para la sesión: por rol y por permiso (ability).
///
/// Regla de seguridad (igual que el inicio histórico): si la tarea no pide
/// permiso, o si todavía no sabemos qué puede el usuario (abilities vacías:
/// login sin `/me`, red o permiso caído), NO se oculta por ability — se cae a
/// filtro solo-rol para no dejar la pantalla vacía. El gating por permiso solo
/// se aplica cuando hay abilities cargadas.
List<RoleTask> visibleTasksFor(Session session, List<RoleTask> tasks) {
  final abilities = session.abilities;
  return tasks.where((task) {
    if (!task.visibleFor(session.role)) {
      return false;
    }
    final required = task.requiredAbility;
    if (required == null || abilities.isEmpty) {
      return true;
    }
    return session.can(required);
  }).toList();
}
