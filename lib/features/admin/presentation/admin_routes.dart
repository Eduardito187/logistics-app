import 'package:go_router/go_router.dart';

import '../../../core/api/models/plan_status.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/icons/icons.dart';
import '../../../core/navigation/role_task.dart';
import '../../supervisor/presentation/supervisor_plans_screen.dart';
import 'admin_broadcasts_screen.dart';
import 'admin_calendar_screen.dart';
import 'admin_reschedule_screen.dart';
import 'admin_shipments_screen.dart';
import 'admin_staff_profile_screen.dart';
import 'admin_staff_screen.dart';
import 'admin_vehicles_screen.dart';

/// Tarjetas de inicio propias del rol Administrador. Además ve las del
/// supervisor (tablero, flota en vivo, rutas en curso, alertas), que declaran
/// ambos roles en `supervisor_routes.dart`.
const List<RoleTask> adminTasks = [
  RoleTask(
    id: 'admin-shipments',
    label: 'Envíos',
    subtitle: 'Buscar por pedido, cliente o ciudad',
    appIcon: AppIcon.receive,
    route: '/admin/shipments',
    roles: {UserRole.planner, UserRole.admin},
  ),
  // VER (no crear) los planes por estado y las rutas con sus paradas y pedidos.
  // Crear/planificar vive aparte (tarjeta "Planificación").
  RoleTask(
    id: 'admin-plans',
    label: 'Planes',
    subtitle: 'Ver por estado · paradas y pedidos',
    appIcon: AppIcon.plans,
    route: '/admin/plans',
    roles: {UserRole.planner, UserRole.admin},
  ),
  RoleTask(
    id: 'admin-routes',
    label: 'Rutas',
    subtitle: 'En ejecución · paradas y pedidos',
    appIcon: AppIcon.route,
    route: '/admin/routes',
    roles: {UserRole.planner, UserRole.admin},
  ),
  RoleTask(
    id: 'admin-staff',
    label: 'Personal',
    subtitle: 'Fichas, documentos y asignaciones',
    appIcon: AppIcon.profile,
    route: '/admin/staff',
    roles: {UserRole.admin},
  ),
  RoleTask(
    id: 'admin-vehicles',
    label: 'Camiones',
    subtitle: 'Estado y mantenimiento',
    appIcon: AppIcon.deliver,
    route: '/admin/vehicles',
    roles: {UserRole.admin},
  ),
  RoleTask(
    id: 'admin-reschedule',
    label: 'Reprogramar pedidos',
    subtitle: 'Por camión o por ciudad',
    appIcon: AppIcon.swap,
    route: '/admin/reschedule',
    roles: {UserRole.planner, UserRole.admin},
  ),
  RoleTask(
    id: 'admin-calendar',
    label: 'Calendario de entregas',
    subtitle: 'Fechas bloqueadas',
    appIcon: AppIcon.myDay,
    route: '/admin/calendar',
    roles: {UserRole.planner, UserRole.admin},
  ),
  RoleTask(
    id: 'admin-broadcasts',
    label: 'Avisos al personal',
    subtitle: 'Por rol, tienda o persona',
    appIcon: AppIcon.send,
    route: '/admin/broadcasts',
    roles: {UserRole.admin},
  ),
];

/// Rutas del módulo de administración. Las que reciben contexto lo toman de
/// `extra` (records tipados) desde `context.push`.
final List<RouteBase> adminRoutes = [
  GoRoute(
    path: '/admin/shipments',
    builder: (context, state) => const AdminShipmentsScreen(),
  ),
  // "Planes": listado de TODOS los planes del día, filtrable por estado.
  GoRoute(
    path: '/admin/plans',
    builder: (context, state) => const SupervisorPlansScreen(
      applyPreset: true,
      titleOverride: 'Planes',
    ),
  ),
  // "Rutas": el mismo listado, pero preseteado a las PUBLICADAS (las que ya son
  // rutas en ejecución). Tocar una abre su detalle con paradas y pedidos.
  GoRoute(
    path: '/admin/routes',
    builder: (context, state) => const SupervisorPlansScreen(
      applyPreset: true,
      presetStatus: PlanStatus.published,
      titleOverride: 'Rutas',
    ),
  ),
  GoRoute(
    path: '/admin/vehicles',
    builder: (context, state) => const AdminVehiclesScreen(),
  ),
  GoRoute(
    path: '/admin/staff',
    builder: (context, state) => const AdminStaffScreen(),
  ),
  GoRoute(
    path: '/admin/staff/:userId',
    builder: (context, state) => AdminStaffProfileScreen(
      userId: int.parse(state.pathParameters['userId']!),
    ),
  ),
  GoRoute(
    path: '/admin/reschedule',
    builder: (context, state) =>
        AdminRescheduleScreen(target: state.extra as RescheduleTarget?),
  ),
  GoRoute(
    path: '/admin/calendar',
    builder: (context, state) => const AdminCalendarScreen(),
  ),
  GoRoute(
    path: '/admin/broadcasts',
    builder: (context, state) =>
        AdminBroadcastsScreen(person: state.extra as BroadcastPerson?),
  ),
];
