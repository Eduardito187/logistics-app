/// El contenido escaneado no es una etiqueta válida (no es JSON, faltan campos, firma mal codificada).
///
/// Una firma que no verifica NO lanza esta excepción: eso es un [VerificationResult],
/// porque en el andén una etiqueta editada es un caso de negocio, no un error.
class LabelFormatException implements Exception {
  LabelFormatException(this.reason);

  final String reason;

  @override
  String toString() => 'Etiqueta inválida: $reason';
}
