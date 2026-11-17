import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import '../home_widgets/role_home_widgets.dart';
import '../navigation/app_nav.dart';
import '../navigation/feature_tasks.dart';
import '../router/app_router.dart';
import 'app_shortcuts_controller.dart';
import 'app_shortcuts_service.dart';
import 'role_shortcuts.dart';

/// Cómo se abre la ruta de un acceso directo / deep-link (push, isla, widget).
///
/// Si la ruta es la ACCIÓN ESTRELLA del rol (p. ej. "Entrega en curso" del
/// chofer), que ES la pestaña CENTRAL del inicio, NO se empuja una pantalla
/// suelta: se va al inicio y se selecciona esa pestaña. Empujarla traía su "X"
/// de cerrar, ocultaba la barra de navegación y se APILABA (el mapa duplicado)
/// al tocar la push varias veces. Así la push/isla cae en el seguimiento del
/// chofer "de verdad" (header + barra, sin X).
///
/// El resto de las rutas se empuja normalmente (después del cuadro en curso: en
/// frío el router recién se monta) y no se repite si ya es la pantalla visible.
/// Seam para tests.
final shortcutNavigatorProvider = Provider<void Function(String route)>((ref) {
  return (route) {
    final binding = SchedulerBinding.instance;
    binding.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      final session = ref.read(sessionProvider);
      final center = session == null
          ? null
          : centerActionFor(session.role, ref.read(featureTasksProvider));
      if (center != null && center.route == route) {
        // Acción estrella = pestaña central del inicio.
        ref.read(homeTabProvider.notifier).set(kHomeCenterTabIndex);
        final current = router.routerDelegate.currentConfiguration.uri.path;
        if (current != AppRoutes.home) router.go(AppRoutes.home);
        return;
      }
      final current = router.routerDelegate.currentConfiguration.uri.path;
      if (current == route) return;
      router.push(route);
    });
    binding.scheduleFrame();
  };
});

/// ARRANQUE de los accesos directos del ícono. Se activa UNA vez desde
/// `LogisticsApp.build`:
///
/// ```dart
/// ref.listen(appShortcutsProvider, (_, _) {});
/// ```
///
/// Publica/borra los accesos según la sesión, abre el acceso con el que se
/// lanzó la app y escucha los que se toquen con la app ya abierta.
final appShortcutsProvider = Provider<void>((ref) {
  final service = ref.watch(appShortcutsServiceProvider);
  final controller = AppShortcutsController(
    service: service,
    navigate: (route) => ref.read(shortcutNavigatorProvider)(route),
    shortcutsOf: (session) =>
        shortcutsFor(session, ref.read(featureTasksProvider)),
    // Toques en los widgets de la pantalla de inicio (viajan por el mismo
    // `shortcut_route`): solo rutas de widgets del rol visibles en su inicio.
    extraRoutesOf: (session) =>
        homeWidgetRoutesFor(session, ref.read(featureTasksProvider)),
  );
  ref.listen<Session?>(
    sessionProvider,
    (_, next) => controller.onSession(next),
    fireImmediately: true,
  );
  final subscription = service.launches.listen(controller.onLaunch);
  ref.onDispose(subscription.cancel);
  unawaited(controller.consumeAtStartup());
});
