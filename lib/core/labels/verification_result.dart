/// Resultado de verificar la firma Ed25519 de una etiqueta (offline).
enum VerificationResult {
  valid,

  /// La firma no corresponde al contenido: etiqueta editada o fabricada.
  invalidSignature,

  /// El id de clave ("k") no está entre las claves públicas que trae la app.
  unknownKey;

  bool get isValid => this == valid;
}
