/// Resultado de la última impresión de prueba, tal como se le muestra al
/// operario (siempre visible y veraz: "aceptó", "no confirma" o el motivo).
class PrintResultMessage {
  const PrintResultMessage(this.text, {required this.tone});

  final String text;
  final PrintResultTone tone;
}

/// Cómo pintar el resultado.
enum PrintResultTone {
  /// La impresora confirmó (IPP aceptó / Zebra lista) o se envió por BT/USB.
  ok,

  /// Se envió pero la impresora no confirma (9100).
  unconfirmed,

  /// Falló: se muestra el motivo.
  error,
}
