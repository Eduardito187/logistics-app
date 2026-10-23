/// Datos para activar 2FA, devueltos por `/app/auth/2fa/enroll`.
///
/// - [secret]: la clave TOTP en texto (para ingreso manual en el autenticador).
/// - [otpauthUri]: URI `otpauth://` con la que se genera el QR EN EL CLIENTE
///   (el backend no entrega imagen).
/// - [recoveryCodes]: 8 códigos de recuperación que se muestran UNA sola vez
///   (cada uno es de un solo uso).
class TwoFactorEnrollment {
  const TwoFactorEnrollment({
    required this.secret,
    required this.otpauthUri,
    required this.recoveryCodes,
  });

  final String secret;
  final String otpauthUri;
  final List<String> recoveryCodes;

  factory TwoFactorEnrollment.fromJson(Map<String, Object?> json) {
    final codes = json['recovery_codes'];
    return TwoFactorEnrollment(
      secret: '${json['secret']}',
      otpauthUri: '${json['otpauth_uri']}',
      recoveryCodes: codes is List
          ? codes.map((e) => '$e').toList(growable: false)
          : const [],
    );
  }
}
