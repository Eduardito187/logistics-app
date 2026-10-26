/// Reto de doble factor que devuelve el login cuando el usuario tiene 2FA
/// activo. `challengeId` es efímero (vive ~5 min, un solo uso) y NO es un token:
/// solo sirve para la verificación del código en el paso siguiente.
class TwoFactorChallenge {
  const TwoFactorChallenge({
    required this.challengeId,
    required this.expiresInSeconds,
  });

  final String challengeId;

  /// Segundos de vida del reto (por defecto 300 = 5 min).
  final int expiresInSeconds;

  factory TwoFactorChallenge.fromJson(Map<String, Object?> json) {
    return TwoFactorChallenge(
      challengeId: '${json['challenge_id']}',
      expiresInSeconds: (json['expires_in'] as num?)?.toInt() ?? 300,
    );
  }
}
