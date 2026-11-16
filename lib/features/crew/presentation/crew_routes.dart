import 'package:go_router/go_router.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/icons/icons.dart';
import '../../../core/navigation/role_task.dart';
import 'crew_shipments_screen.dart';

/// Tareas del inicio del TRIPULANTE. "Mis envíos" es su acción principal
/// (botón central del shell). Consultar pedido y Ajustes los aporta cada feature
/// a su propia lista (lookup/settings) sumando este rol.
const List<RoleTask> crewTasks = [
  RoleTask(
    id: 'crew-shipments',
    label: 'Mis envíos',
    subtitle: 'Los pedidos del camión en el que vas',
    appIcon: AppIcon.orders,
    route: '/crew/shipments',
    roles: {UserRole.crewMember},
    accent: true,
  ),
];

final List<RouteBase> crewRoutes = [
  GoRoute(
    path: '/crew/shipments',
    builder: (context, state) => const CrewShipmentsScreen(),
  ),
];
