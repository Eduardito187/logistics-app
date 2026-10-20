import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/carrier/presentation/carrier_routes.dart';
import '../../features/driver/presentation/driver_routes.dart';
import '../../features/picking/presentation/picking_routes.dart';
import '../../features/settings/presentation/settings_routes.dart';
import '../../features/store/presentation/store_routes.dart';
import '../../features/supervisor/presentation/supervisor_routes.dart';
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
