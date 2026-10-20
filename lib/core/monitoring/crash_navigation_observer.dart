import 'package:flutter/widgets.dart';

import 'crash_reporter.dart';

/// Observer de navegación que deja migas de pan en el [CrashReporter]
/// (`nav.push /driver/route`). Usa el nombre/patrón de la ruta (go_router pone
/// el path con parámetros, p. ej. `/shipments/:id`), nunca los argumentos.
/// Si llega un path concreto, [sanitizeBreadcrumb] enmascara los ids.
///
/// Se pasa a `GoRouter(observers: [...])`.
class CrashNavigationObserver extends NavigatorObserver {
  CrashNavigationObserver(this._reporter);

  final CrashReporter _reporter;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('push', route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('pop', route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _log('replace', newRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('remove', route);

  void _log(String action, Route<dynamic>? route) {
    if (route is! PageRoute) return; // diálogos y bottom sheets no suman
    final name = route.settings.name ?? 'sin_nombre';
    _reporter.breadcrumb('nav.$action $name');
  }
}
