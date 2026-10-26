import 'package:go_router/go_router.dart';

import '../domain/entities/two_factor_challenge.dart';
import 'forgot_password_screen.dart';
import 'security_screen.dart';
import 'two_factor_challenge_screen.dart';

/// Rutas del feature auth que se suman al router global:
/// - `/login/2fa` y `/login/forgot`: PÚBLICAS (se ven sin sesión; el redirect
///   del router las habilita, ver `app_router.dart`).
/// - `/settings/security`: Ajustes › Seguridad (requiere sesión).
final List<RouteBase> authRoutes = [
  GoRoute(
    path: '/login/2fa',
    builder: (context, state) =>
        TwoFactorChallengeScreen(challenge: state.extra! as TwoFactorChallenge),
  ),
  GoRoute(
    path: '/login/forgot',
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: '/settings/security',
    builder: (context, state) => const SecurityScreen(),
  ),
];
