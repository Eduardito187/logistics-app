/// Resultado de pedir la biometría al sistema (método `authenticate` del canal).
enum BiometricResult {
  /// Rostro/huella reconocido.
  success,

  /// El usuario canceló o eligió usar la contraseña: no se avisa nada.
  cancelled,

  /// Demasiados intentos fallidos: el sistema bloqueó la biometría un rato.
  lockout,

  /// El teléfono tiene sensor pero no hay nada registrado.
  notEnrolled,

  /// Sin sensor, sensor ocupado o canal nativo ausente.
  notAvailable,

  /// Cualquier otro error del sistema.
  failed;

  /// Resultado a partir del texto del canal; desconocido → [failed].
  static BiometricResult fromWire(Object? raw) {
    for (final result in values) {
      if (result.name == raw) return result;
    }
    return failed;
  }
}
