/// Resultado de guardar la impresora activa en ajustes.
enum PrinterSaveResult {
  /// Se guardó como impresora activa.
  saved,

  /// Ya era la activa (idéntica): no se reescribió.
  unchanged,

  /// No se pudo guardar (almacén seguro).
  failed,
}
