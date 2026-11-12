import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/feature_tasks.dart';
import 'package:logistics_app/core/navigation/role_task.dart';
import 'package:logistics_app/core/shortcuts/app_shortcut.dart';
import 'package:logistics_app/core/shortcuts/app_shortcuts_controller.dart';
import 'package:logistics_app/core/shortcuts/app_shortcuts_provider.dart';
import 'package:logistics_app/core/shortcuts/app_shortcuts_service.dart';
import 'package:logistics_app/core/shortcuts/role_shortcuts.dart';

/// Servicio falso: registra lo publicado y simula el acceso de arranque.
class _FakeShortcuts extends AppShortcutsService {
  String? launchRoute;
  final List<String> calls = [];
  List<AppShortcut> published = const [];

  @override
  Stream<String> get launches => const Stream.empty();

  @override
  Future<void> set(List<AppShortcut> shortcuts) async {
    calls.add('set');
    published = shortcuts;
  }

  @override
  Future<void> clear() async {
    calls.add('clear');
    published = const [];
  }

  @override
  Future<String?> consumeLaunchShortcut() async {
    final route = launchRoute;
    launchRoute = null;
    return route;
  }
}

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier(this._initial);

  final Session? _initial;

  @override
  Session? build() => _initial;

  void set(Session? session) => state = session;
}

const _driver = Session(userName: 'chofer', role: UserRole.driver);
const _store = Session(userName: 'tienda', role: UserRole.store);

void main() {
  late List<RoleTask> tasks;
  late _FakeShortcuts service;
  late List<String> navigated;
  late AppShortcutsController controller;

  setUp(() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    tasks = container.read(featureTasksProvider);
    service = _FakeShortcuts();
    navigated = [];
    controller = AppShortcutsController(
      service: service,
      navigate: navigated.add,
      shortcutsOf: (s) => shortcutsFor(s, tasks),
    );
  });

  group('controller', () {
    test('al iniciar sesión publica los accesos del rol', () {
      controller.onSession(_driver);
      expect(service.calls, ['set']);
      expect(service.published.first.route, '/driver/delivery');
    });

    test('al cerrar sesión los borra', () {
      controller.onSession(_driver);
      controller.onSession(null);
      expect(service.calls, ['set', 'clear']);
      expect(service.published, isEmpty);
    });

    test('la misma lista no se vuelve a publicar', () {
      controller.onSession(_driver);
      controller.onSession(_driver);
      expect(service.calls, ['set']);
    });

    test('cambio de rol reemplaza los accesos', () {
      controller.onSession(_driver);
      controller.onSession(_store);
      expect(service.calls, ['set', 'set']);
      expect(service.published.first.route, '/store/reception');
    });

    test('acceso tocado con sesión → navega', () {
      controller.onSession(_driver);
      controller.onLaunch('/driver/route');
      expect(navigated, ['/driver/route']);
    });

    test('acceso de otro rol o ruta ajena → no navega', () {
      controller.onSession(_store);
      controller.onLaunch('/driver/delivery');
      controller.onLaunch('/settings/printer');
      expect(navigated, isEmpty);
    });

    test('acceso sin sesión queda pendiente hasta el login', () {
      controller.onSession(null);
      controller.onLaunch('/store/reception');
      expect(navigated, isEmpty);
      expect(controller.pendingRoute, '/store/reception');
      controller.onSession(_store);
      expect(navigated, ['/store/reception']);
      expect(controller.pendingRoute, isNull);
    });

    test('arranque en frío desde un acceso navega una sola vez', () async {
      service.launchRoute = '/driver/delivery';
      controller.onSession(_driver);
      await controller.consumeAtStartup();
      await controller.consumeAtStartup();
      expect(navigated, ['/driver/delivery']);
    });
  });

  group('provider de arranque', () {
    test('publica, navega al acceso de arranque y borra al salir', () async {
      service.launchRoute = '/driver/delivery';
      final container = ProviderContainer(
        overrides: [
          appShortcutsServiceProvider.overrideWithValue(service),
          sessionProvider.overrideWith(() => _TestSessionNotifier(_driver)),
          shortcutNavigatorProvider.overrideWithValue(navigated.add),
        ],
      );
      addTearDown(container.dispose);
      container.listen(appShortcutsProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      expect(service.calls, ['set']);
      expect(navigated, ['/driver/delivery']);

      (container.read(sessionProvider.notifier) as _TestSessionNotifier).set(
        null,
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.calls, ['set', 'clear']);
    });
  });
}
