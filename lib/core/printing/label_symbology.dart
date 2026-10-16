/// Qué símbolos lleva la etiqueta del bulto.
///
/// El QR SIEMPRE lleva el JSON firmado Ed25519 completo: es el que se escanea y
/// se verifica offline en todas las etapas, y un código de barras 1D no alcanza
/// para ese payload. El Code128 es un secundario legible con el id corto del
/// bulto (útil para un lector láser de mano o lectura humana rápida).
enum LabelSymbology {
  /// Solo QR firmado (comportamiento histórico, layout original).
  qr,

  /// Solo Code128 con el id corto (sin verificación offline; poco habitual).
  barcode,

  /// QR firmado + Code128 con el id corto.
  both,
}
