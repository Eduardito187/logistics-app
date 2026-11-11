import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/home_widgets/home_widget_kind.dart';
import 'package:logistics_app/core/home_widgets/home_widgets_prefs.dart';
import 'package:logistics_app/core/home_widgets/role_home_widgets.dart';
import 'package:logistics_app/core/navigation/feature_tasks.dart';
import 'package:logistics_app/core/navigation/role_task.dart';
import 'package:logistics_app/core/router/app_router.dart';
import 'package:logistics_app/core/shortcuts/app_shortcut.dart';
import 'package:logistics_app/core/shortcuts/app_shortcuts_controller.dart';
import 'package:logistics_app/core/shortcuts/app_shortcuts_service.dart';
import 'package:logistics_app/core/shortcuts/role_shortcuts.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_routes.dart';
import 'package:logistics_app/features/driver/presentation/driver_routes.dart';
import 'package:logistics_app/features/picking/presentation/picking_routes.dart';
import 'package:logistics_app/features/store/presentation/store_routes.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_routes.dart';

// Toda ruta que un widget abre EXISTE en go_router, es una tarea real del rol
// y el controller de accesos directos la acepta (solo las del rol).

class _NoopShortcuts extends AppShortcutsService {
  @override
  Stream<String> get launches => const Stream.empty();

  @override
  Future<void> set(List<AppShortcut> shortcuts) async {}

  @override
  Future<void> clear() async {}
}

Set<String> _goRoutePaths() => {
  for (final route in [
    ...driverRoutes,
    ...pickingRoutes,
    ...storeRoutes,
    ...carrierRoutes,
    ...supervisorRoutes,
  ])
    if (route is GoRoute) route.path,
};

void main() {
  late List<RoleTask> tasks;

  setUp(() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    tasks = container.read(featureTasksProvider);
  });

  test('las rutas fijas de sesión coinciden con AppRoutes', () {
    expect(kHomeWidgetSignedOutRoute, AppRoutes.login);
    expect(kHomeWidgetNotAllowedRoute, AppRoutes.home);
  });

  test('cada ruta de widget existe y es una tarea del rol', () {
    final paths = _goRoutePaths();
    for (final role in UserRole.values) {
      final taskRoutes = {
        for (final t in tasks)
          if (t.visibleFor(role)) t.route,
      };
      final routes = [
        for (final kind in homeWidgetKindsFor(role))
          homeWidgetRouteFor(kind, role)!,
        if (homeWidgetKindsFor(role).contains(HomeWidgetKind.pickingPending))
          kPickingScanRoute,
      ];
      for (final route in routes) {
        expect(paths, contains(route), reason: '$role → $route');
        expect(taskRoutes, contains(route), reason: '$role → $route');
      }
    }
  });

  test('kind de otro rol no tiene ruta', () {
    expect(
      homeWidgetRouteFor(HomeWidgetKind.nextDelivery, UserRole.picker),
      isNull,
    );
  });

  test('backendKey ida y vuelta', () {
    for (final kind in HomeWidgetKind.values) {
      expect(HomeWidgetKind.fromBackendKey(kind.backendKey), kind);
    }
    expect(HomeWidgetKind.fromBackendKey('otro'), isNull);
  });

  test('prefs: JSON ida y vuelta y corrupto → por defecto', () {
    const prefs = HomeWidgetsPrefs(
      userKey: 'u',
      disabledKinds: {HomeWidgetKind.routeDay},
      hideCustomer: true,
    );
    expect(HomeWidgetsPrefs.decode('u', prefs.encode()), prefs);
    expect(
      HomeWidgetsPrefs.decode('u', '{no json'),
      const HomeWidgetsPrefs(userKey: 'u'),
    );
  });

  group('accesos directos aceptan rutas de widgets', () {
    late List<String> navigated;
    late AppShortcutsController controller;

    setUp(() {
      navigated = [];
      controller = AppShortcutsController(
        service: _NoopShortcuts(),
        navigate: navigated.add,
        shortcutsOf: (s) => shortcutsFor(s, tasks),
        extraRoutesOf: (s) => homeWidgetRoutesFor(s, tasks),
      );
    });

    test('preparador: "Escanear" del widget abre ingresar pedido', () {
      controller.onSession(
        const Session(userName: 'p', role: UserRole.picker),
      );
      controller.onLaunch('/picking/prepare');
      expect(navigated, ['/picking/prepare']);
    });

    test('supervisor: el widget abre el tablero', () {
      controller.onSession(
        const Session(userName: 's', role: UserRole.supervisor),
      );
      controller.onLaunch('/supervisor/dashboard');
      expect(navigated, ['/supervisor/dashboard']);
    });

    test('ruta de otro rol, /home o /login no navegan', () {
      controller.onSession(
        const Session(userName: 'p', role: UserRole.picker),
      );
      controller.onLaunch('/driver/delivery');
      controller.onLaunch('/home');
      controller.onLaunch('/login');
      expect(navigated, isEmpty);
    });
  });
}
