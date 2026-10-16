import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/navigation/role_task.dart';
import 'notification_detail_screen.dart';
import 'notifications_list_screen.dart';

/// Rutas del feature de notificaciones, para enchufar en el router global.
final List<RouteBase> notificationsRoutes = [
  GoRoute(
    path: '/notifications',
    builder: (context, state) => const NotificationsListScreen(),
  ),
  GoRoute(
    path: '/notifications/:id',
    builder: (context, state) =>
        NotificationDetailScreen(id: state.pathParameters['id']!),
  ),
];

/// Tarjeta de inicio para abrir la bandeja. Visible para todos los roles.
const List<RoleTask> notificationsTasks = [
  RoleTask(
    id: 'notifications',
    label: 'Notificaciones',
    icon: Icons.notifications,
    route: '/notifications',
    roles: {
      UserRole.driver,
      UserRole.picker,
      UserRole.store,
      UserRole.carrier,
      UserRole.supervisor,
    },
  ),
];
