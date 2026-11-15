import 'package:go_router/go_router.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/icons/icons.dart';
import '../../../core/navigation/role_task.dart';
import 'counter_pickup_screen.dart';
import 'node_reception_screen.dart';
import 'pickup_pod_screen.dart';
import 'reception_detail_screen.dart';

/// Tarjetas de inicio del rol Tienda.
///
/// Decisión del dueño (nov 2026): la tienda SOLO entrega al cliente final. La
/// llegada del pedido a la tienda la marca el CHOFER al dejarlo ("Entregar en
/// tienda"), no el personal de tienda: por eso ya no hay tarjeta de "Recepción
/// de mercadería" (sus pantallas quedan sin acceso desde la app).
const List<RoleTask> storeTasks = [
  RoleTask(
    id: 'store-pickup',
    label: 'Recojo en tienda',
    subtitle: 'Entrega al cliente',
    appIcon: AppIcon.pickupStore,
    route: '/store/pickup',
    roles: {UserRole.store},
    accent: true,
  ),
];

/// Rutas del flujo Tienda. Las pantallas de detalle reciben su contexto por
/// `extra` (records tipados) desde `context.push`.
final List<RouteBase> storeRoutes = [
  GoRoute(
    path: '/store/reception',
    builder: (context, state) => const NodeReceptionScreen(),
  ),
  GoRoute(
    path: '/store/reception/detail',
    builder: (context, state) =>
        ReceptionDetailScreen(args: state.extra! as ReceptionArgs),
  ),
  GoRoute(
    path: '/store/pickup',
    builder: (context, state) => const CounterPickupScreen(),
  ),
  GoRoute(
    path: '/store/pickup/pod',
    builder: (context, state) =>
        PickupPodScreen(shipment: state.extra! as Shipment),
  ),
];
