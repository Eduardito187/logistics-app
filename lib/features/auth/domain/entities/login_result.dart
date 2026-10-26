import 'two_factor_challenge.dart';

/// Resultado del intento de login.
///
/// - [LoginSignedIn]: credenciales OK y el usuario NO tiene 2FA → la sesión ya
///   quedó abierta y el router redirige solo al inicio.
/// - [LoginNeedsTwoFactor]: credenciales OK pero el usuario tiene 2FA → todavía
///   NO hay sesión; hay que verificar el código con el [TwoFactorChallenge].
sealed class LoginResult {
  const LoginResult();
}

class LoginSignedIn extends LoginResult {
  const LoginSignedIn();
}

class LoginNeedsTwoFactor extends LoginResult {
  const LoginNeedsTwoFactor(this.challenge);

  final TwoFactorChallenge challenge;
}
