/// Resultado de verificar una etiqueta (offline).
enum VerificationResult {
  /// Firma Ed25519 correcta (etiqueta FIRMADA, k>0).
  valid,

  /// La firma no corresponde al contenido: etiqueta editada o fabricada.
  invalidSignature,

  /// El id de clave ("k") no está entre las claves públicas que trae la app.
  unknownKey,

  /// Etiqueta ABIERTA (`k:0`, sin firma): NO se verifica Ed25519. No se rechaza
  /// por firma; su autenticidad la decide el registro/pertenencia aguas abajo
  /// (que el `id` resuelva y pertenezca al envío/ruta). Ver `LabelPayload.openKeyId`.
  open;

  /// La capa de firma ACEPTA la etiqueta: firmada y válida, o abierta (que no se
  /// decide por firma). La pertenencia del producto la validan los flujos de
  /// campo (comparando el id contra los productos esperados).
  bool get isValid => this == valid || this == open;
}
