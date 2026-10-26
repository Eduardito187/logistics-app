import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_routes.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/carrier/presentation/carrier_routes.dart';
import '../../features/driver/presentation/driver_routes.dart';
import '../../features/notifications/presentation/notifications_routes.dart';
import '../../features/picking/presentation/picking_routes.dart';
import '../../features/settings/presentation/settings_routes.dart';
import '../../features/store/presentation/store_routes.dart';
import '../../features/supervisor/presentation/supervisor_routes.dart';
import '../../features/sync/presentation/sync_screen.dart';
import '../auth/session.dart';
import '../monitoring/crash_navigation_observer.dart';
import '../monitoring/crash_reporter.dart';
import '../navigation/home_shell.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const twoFactor = '/login/2fa';
  static const forgotPassword = '/login/forgot';
  static const home = '/home';
  static const tasks = '/tareas';
  static const notifications = '/avisos';
  static const profile = '/perfil';
  static const sync = '/sync';
}

/// Rutas de autenticación visibles SIN sesión (login y sus pasos). El resto
/// redirige al login cuando no hay sesión.
const _publicAuthPaths = {
  AppRoutes.login,
  AppRoutes.twoFactor,
  AppRoutes.forgotPassword,
};

/// Navigator raíz: los flujos profundos (campo) se empujan acá, POR ENCIMA del
/// shell, a pantalla completa y sin barra inferior.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Router con redirección por sesión: sin sesión todo lleva al login;
/// con sesión, el login lleva al inicio del rol. Cada feature aporta sus rutas.
final routerProvider = Provider<GoRouter>((ref) {
  // Puente entre Riverpod y go_router: el router se re-evalúa cuando cambia la
  // sesión, sin reconstruir el GoRouter (que perdería el stack de navegación).
  final sessionChanges = ValueNotifier<Session?>(null);
  ref.listen(
    sessionProvider,
    (_, next) => sessionChanges.value = next,
    fireImmediately: true,
  );
  ref.onDispose(sessionChanges.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    // Rastro de navegación para Crashlytics (patrón de ruta, sin ids).
    observers: [CrashNavigationObserver(ref.read(crashReporterProvider))],
    refreshListenable: sessionChanges,
    redirect: (context, state) {
      final signedIn = ref.read(sessionProvider) != null;
      final isPublicAuth = _publicAuthPaths.contains(state.matchedLocation);
      // Sin sesión: solo se ven las pantallas públicas de login (incluido el
      // paso 2FA y el reseteo de contraseña); todo lo demás va al login.
      if (!signedIn) return isPublicAuth ? null : AppRoutes.login;
      // Con sesión: esas pantallas públicas ya no aplican → al inicio del rol.
      if (isPublicAuth) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // Shell con barra inferior flotante: las cuatro pestañas (Inicio, Tareas,
      // Avisos, Perfil) viven en un IndexedStack DENTRO de HomeShell (cambio de
      // pestaña en la misma pantalla, por índice, conserva el estado). El resto
      // de las rutas son hermanas y se abren a pantalla completa por encima.
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: AppRoutes.sync,
        builder: (context, state) => const SyncScreen(),
      ),
      // Rutas de campo: entregas y despacho. Hermanas del shell → pantalla
      // completa sobre el navigator raíz (sin barra inferior).
      ...authRoutes,
      ...pickingRoutes,
      ...driverRoutes,
      ...storeRoutes,
      ...carrierRoutes,
      ...supervisorRoutes,
      ...notificationsRoutes,
      ...settingsRoutes,
    ],
  );
});
