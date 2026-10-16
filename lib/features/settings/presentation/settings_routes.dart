import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/navigation/role_task.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';

/// Rutas del feature de ajustes, para enchufar en el router global.
final List<RouteBase> settingsRoutes = [
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: '/settings/devices',
    builder: (context, state) => const DevicesScreen(),
  ),
];

/// Tarjeta de inicio para abrir ajustes. Visible para todos los roles.
const List<RoleTask> settingsTasks = [
  RoleTask(
    id: 'settings',
    label: 'Ajustes',
    icon: Icons.settings,
    route: '/settings',
    roles: {
      UserRole.driver,
      UserRole.picker,
      UserRole.store,
      UserRole.carrier,
      UserRole.supervisor,
    },
  ),
];
