import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/role_task.dart';

// RoleTask es la tarjeta de acción del inicio; se filtra por rol y, opcional,
// por ability. Se cubren sus defaults y el filtro visibleFor.
void main() {
  group('RoleTask', () {
    test('guarda sus campos y aplica defaults', () {
      const task = RoleTask(
        id: 't1',
        label: 'Ruta',
        icon: Icons.map,
        route: '/driver/route',
        roles: {UserRole.driver},
      );
      expect(task.id, 't1');
      expect(task.label, 'Ruta');
      expect(task.route, '/driver/route');
      expect(task.roles, {UserRole.driver});
      // Defaults.
      expect(task.subtitle, isNull);
      expect(task.requiredAbility, isNull);
      expect(task.accent, isFalse);
    });

    test('acepta subtitle, accent y requiredAbility', () {
      const task = RoleTask(
        id: 't2',
        label: 'Carga',
        icon: Icons.inventory,
        route: '/picking/prepare',
        roles: {UserRole.picker},
        subtitle: 'Valida la carga',
        accent: true,
        requiredAbility: 'execution:write',
      );
      expect(task.subtitle, 'Valida la carga');
      expect(task.accent, isTrue);
      expect(task.requiredAbility, 'execution:write');
    });

    test('visibleFor es true solo para los roles declarados', () {
      const task = RoleTask(
        id: 't3',
        label: 'x',
        icon: Icons.abc,
        route: '/x',
        roles: {UserRole.driver, UserRole.supervisor},
      );
      expect(task.visibleFor(UserRole.driver), isTrue);
      expect(task.visibleFor(UserRole.supervisor), isTrue);
      expect(task.visibleFor(UserRole.picker), isFalse);
      expect(task.visibleFor(UserRole.store), isFalse);
      expect(task.visibleFor(UserRole.carrier), isFalse);
    });
  });
}
