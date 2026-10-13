import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/role_home_screen.dart';
import '../auth/session.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/home';
}

/// Router con redirección por sesión: sin sesión todo lleva al login;
/// con sesión, el login lleva al inicio del rol.
final routerProvider = Provider<GoRouter>((ref) {
  // Puente entre Riverpod y go_router: el router se re-evalúa cuando cambia la sesión,
  // sin reconstruir el GoRouter (que perdería el stack de navegación).
  final sessionChanges = ValueNotifier<Session?>(null);
  ref.listen(
    sessionProvider,
    (_, next) => sessionChanges.value = next,
    fireImmediately: true,
  );
  ref.onDispose(sessionChanges.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: sessionChanges,
    redirect: (context, state) {
      final signedIn = ref.read(sessionProvider) != null;
      final atLogin = state.matchedLocation == AppRoutes.login;
      if (!signedIn) return atLogin ? null : AppRoutes.login;
      if (atLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const RoleHomeScreen(),
      ),
    ],
  );
});
