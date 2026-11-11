import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/feature_tasks.dart';
import 'package:logistics_app/core/navigation/role_task.dart';
import 'package:logistics_app/core/shortcuts/role_shortcuts.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_routes.dart';
import 'package:logistics_app/features/driver/presentation/driver_routes.dart';
import 'package:logistics_app/features/picking/presentation/picking_routes.dart';
import 'package:logistics_app/features/store/presentation/store_routes.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_routes.dart';

void main() {
  late List<RoleTask> tasks;

  setUp(() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    tasks = container.read(featureTasksProvider);
  });

  List<String> routesFor(UserRole role, {List<String> abilities = const []}) =>
      shortcutsFor(
        Session(userName: 'u', role: role, abilities: abilities),
        tasks,
      ).map((s) => s.route).toList();

  test('chofer: entrega en curso primero, máximo 4', () {
    final shortcuts = shortcutsFor(
      const Session(userName: 'u', role: UserRole.driver),
      tasks,
    );
    expect(shortcuts.length, lessThanOrEqualTo(kMaxAppShortcuts));
    expect(shortcuts.first.route, '/driver/delivery');
    expect(shortcuts.first.title, 'Entrega en curso');
    expect(shortcuts.first.shortTitle, 'Entrega');
    expect(routesFor(UserRole.driver), contains('/driver/route'));
  });

  test('cada rol recibe SOLO sus accesos', () {
    expect(routesFor(UserRole.picker), ['/picking/orders', '/picking/prepare']);
    expect(routesFor(UserRole.store), ['/store/reception', '/store/pickup']);
    expect(routesFor(UserRole.carrier), [
      '/carrier/pickup',
      '/carrier/deliver',
    ]);
    expect(routesFor(UserRole.supervisor).first, '/supervisor/fleet');
    expect(
      routesFor(UserRole.picker).any((r) => r.startsWith('/driver')),
      isFalse,
    );
  });

  test('textos cortos entran en el launcher (≤ 10 caracteres)', () {
    for (final role in UserRole.values) {
      for (final s in shortcutsFor(Session(userName: 'u', role: role), tasks)) {
        expect(s.shortTitle.length, lessThanOrEqualTo(10), reason: s.id);
        expect(s.title.length, lessThanOrEqualTo(25), reason: s.id);
      }
    }
  });

  test('todas las rutas de los accesos existen en el router', () {
    final paths = <String>{};
    void collect(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute) paths.add(r.path);
        collect(r.routes);
      }
    }

    collect([
      ...driverRoutes,
      ...pickingRoutes,
      ...storeRoutes,
      ...carrierRoutes,
      ...supervisorRoutes,
    ]);
    for (final role in UserRole.values) {
      for (final s in shortcutsFor(Session(userName: 'u', role: role), tasks)) {
        expect(paths, contains(s.route), reason: s.id);
      }
    }
  });

  test('respeta el permiso (ability) igual que el inicio', () {
    final gated = [
      RoleTask(
        id: 'driver-active-delivery',
        label: 'Entrega en curso',
        appIcon: tasks.first.appIcon,
        route: '/driver/delivery',
        roles: const {UserRole.driver},
        requiredAbility: 'execution:write',
      ),
    ];
    expect(
      shortcutsFor(
        const Session(
          userName: 'u',
          role: UserRole.driver,
          abilities: ['other'],
        ),
        gated,
      ),
      isEmpty,
    );
    // Sin abilities cargadas (degradación segura): se muestra.
    expect(
      shortcutsFor(const Session(userName: 'u', role: UserRole.driver), gated),
      hasLength(1),
    );
  });
}
