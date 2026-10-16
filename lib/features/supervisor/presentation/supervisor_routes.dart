import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/navigation/role_task.dart';
import 'supervisor_alerts_screen.dart';
import 'supervisor_dashboard_screen.dart';
import 'supervisor_fleet_screen.dart';
import 'supervisor_plan_detail_screen.dart';
import 'supervisor_plans_screen.dart';

/// Tarjetas de inicio del rol supervisor (torre de control en el bolsillo).
const List<RoleTask> supervisorTasks = [
  RoleTask(
    id: 'sup-dashboard',
    label: 'Tablero del día',
    icon: Icons.dashboard,
    route: '/supervisor/dashboard',
    roles: {UserRole.supervisor},
    accent: true,
  ),
  RoleTask(
    id: 'sup-fleet',
    label: 'Flota en vivo',
    icon: Icons.map,
    route: '/supervisor/fleet',
    roles: {UserRole.supervisor},
  ),
  RoleTask(
    id: 'sup-plans',
    label: 'Rutas en curso',
    icon: Icons.alt_route,
    route: '/supervisor/plans',
    roles: {UserRole.supervisor},
  ),
  RoleTask(
    id: 'sup-alerts',
    label: 'Alertas',
    icon: Icons.notification_important,
    route: '/supervisor/alerts',
    roles: {UserRole.supervisor},
  ),
];

/// Rutas go_router del rol supervisor.
final List<RouteBase> supervisorRoutes = [
  GoRoute(
    path: '/supervisor/dashboard',
    builder: (context, state) => const SupervisorDashboardScreen(),
  ),
  GoRoute(
    path: '/supervisor/fleet',
    builder: (context, state) => const SupervisorFleetScreen(),
  ),
  GoRoute(
    path: '/supervisor/plans',
    builder: (context, state) => const SupervisorPlansScreen(),
  ),
  GoRoute(
    path: '/supervisor/alerts',
    builder: (context, state) => const SupervisorAlertsScreen(),
  ),
  // Detalle (solo lectura) de un plan de ruta por id.
  GoRoute(
    path: '/supervisor/plans/:planId',
    builder: (context, state) =>
        SupervisorPlanDetailScreen(planId: state.pathParameters['planId']!),
  ),
];
