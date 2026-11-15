import 'package:go_router/go_router.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/icons/icons.dart';
import '../../../core/navigation/role_task.dart';
import 'order_lookup_screen.dart';

/// "Consultar pedido" es de TODOS los roles (decisión del dueño): cualquiera
/// puede escanear una etiqueta para saber de qué pedido es y en qué estado
/// está, tenga o no permiso para procesarlo.
const List<RoleTask> lookupTasks = [
  RoleTask(
    id: 'order-lookup',
    label: 'Consultar pedido',
    subtitle: 'Escaneá una etiqueta o buscá el código',
    appIcon: AppIcon.search,
    route: '/lookup',
    roles: {
      UserRole.driver,
      UserRole.picker,
      UserRole.store,
      UserRole.carrier,
      UserRole.supervisor,
      UserRole.admin,
    },
  ),
];

final List<RouteBase> lookupRoutes = [
  GoRoute(
    path: '/lookup',
    builder: (context, state) =>
        OrderLookupScreen(initialQuery: state.extra as String?),
  ),
];
