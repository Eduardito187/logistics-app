import '../entities/login_result.dart';
import '../entities/two_factor_enrollment.dart';

/// Contrato de autenticación de la app interna. La capa `data` lo implementa;
/// la capa `presentation` sólo lo conoce a través de los casos de uso.
abstract interface class AuthRepository {
  /// Autentica contra la puerta `/app/*` (A-02): usuario + contraseña +
  /// dispositivo. Devuelve [LoginSignedIn] (sesión abierta) o
  /// [LoginNeedsTwoFactor] (falta verificar el código). Lanza `ApiException`.
  Future<LoginResult> login({required String email, required String password});

  /// Verifica el código 2FA (TOTP o recovery) contra el reto y, si es válido,
  /// abre la sesión. Lanza `ApiException` (422 = código inválido/expirado).
  Future<void> verifyTwoFactor({
    required String challengeId,
    required String code,
  });

  /// Inicia la activación de 2FA: devuelve secreto, URI otpauth y recovery codes.
  Future<TwoFactorEnrollment> enrollTwoFactor();

  /// Confirma y activa el 2FA con un código válido del autenticador.
  Future<void> confirmTwoFactor(String code);

  /// Desactiva el 2FA, con código (TOTP/recovery) o con la contraseña actual.
  Future<void> disableTwoFactor({String? code, String? password});

  /// Solicita el envío del código de reseteo al correo (respuesta genérica).
  Future<void> forgotPassword(String email);

  /// Cambia la contraseña con el código recibido por correo.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  });
}
