import 'package:flutter/material.dart';

import '../auth/user_role.dart';

/// Una tarjeta de acción en el inicio del rol. Cada feature aporta las suyas y
/// el inicio las filtra por el rol de la sesión.
@immutable
class RoleTask {
  const RoleTask({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.roles,
    this.subtitle,
    this.accent = false,
    this.requiredAbility,
  });

  final String id;
  final String label;
  final String? subtitle;
  final IconData icon;

  /// Ruta go_router a la que navega la tarjeta.
  final String route;

  /// Roles que ven esta tarjeta.
  final Set<UserRole> roles;

  /// Permiso (ability) del token requerido para ver esta tarjeta, p. ej.
  /// `'execution:write'`. Opcional: si es `null`, la tarjeta se filtra solo por
  /// rol. El gating por permiso es seguro: el inicio solo oculta por ability
  /// cuando la sesión tiene abilities cargadas (ver [RoleHomeScreen]).
  final String? requiredAbility;

  /// Resalta la tarjeta como acción principal del rol.
  final bool accent;

  bool visibleFor(UserRole role) => roles.contains(role);
}
