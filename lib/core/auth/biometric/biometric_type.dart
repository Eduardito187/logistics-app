/// Tipo de sensor biométrico que el teléfono declara tener.
///
/// El valor de cable (`wire`) es el que manda el canal nativo
/// (`bo.com.dismac/biometric`, método `capabilities`).
enum BiometricType {
  fingerprint('fingerprint'),
  face('face'),
  iris('iris');

  const BiometricType(this.wire);

  final String wire;

  /// Tipo a partir del texto del canal; `null` si es desconocido (se ignora).
  static BiometricType? fromWire(Object? raw) {
    for (final type in values) {
      if (type.wire == raw) return type;
    }
    return null;
  }
}
