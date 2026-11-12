import 'biometric_capabilities.dart';
import 'biometric_result.dart';

/// Textos para el usuario según el resultado de la biometría. Compartidos por
/// el login (feature auth) y el perfil (feature settings).
abstract final class BiometricMessages {
  /// Aviso tras intentar ACTIVAR el ingreso con biometría. `null` = no avisar
  /// (el usuario canceló).
  static String? enable(BiometricResult result, BiometricCapabilities caps) =>
      switch (result) {
        BiometricResult.success =>
          'Listo: la próxima vez ingresá con ${caps.label}.',
        BiometricResult.cancelled => null,
        BiometricResult.lockout => 'Demasiados intentos. Probá más tarde.',
        BiometricResult.notEnrolled => caps.setupHint,
        BiometricResult.notAvailable || BiometricResult.failed =>
          'No se pudo activar ${caps.labelWithArticle}. Probá de nuevo.',
      };

  /// Aviso tras intentar INGRESAR con biometría (antes del login). `null` =
  /// no avisar (éxito o cancelado).
  static String? signIn(BiometricResult result, BiometricCapabilities caps) =>
      switch (result) {
        BiometricResult.success || BiometricResult.cancelled => null,
        BiometricResult.lockout => 'Demasiados intentos. Usá tu contraseña.',
        BiometricResult.notEnrolled => caps.setupHint,
        BiometricResult.notAvailable || BiometricResult.failed =>
          'No se pudo usar ${caps.labelWithArticle}. Ingresá con tu '
              'contraseña.',
      };

  /// La contraseña guardada ya no sirve (se cambió): se borró la credencial.
  static String passwordChanged(BiometricCapabilities caps) =>
      'Tu contraseña cambió. Ingresá con tu contraseña y volvé a activar '
      '${caps.labelWithArticle}.';
}
