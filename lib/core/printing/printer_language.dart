/// Lenguaje/tipo de documento que entiende la impresora.
///
/// - [zpl]: etiquetadoras Zebra; se les manda el ZPL firmado tal cual.
/// - [office]: impresoras de oficina (láser/tinta: Ricoh, HP, Canon…). NO
///   entienden ZPL (lo imprimirían como texto): la app les manda la etiqueta
///   rasterizada como PDF/PWG por IPP o PCL por el puerto 9100.
enum PrinterLanguage {
  zpl('Etiquetas Zebra (ZPL)'),
  office('Impresora de oficina (PDF)');

  const PrinterLanguage(this.label);

  /// Etiqueta legible para la UI (español).
  final String label;

  /// Desconocido o vacío → [zpl] (compatibilidad con configs viejas).
  static PrinterLanguage fromName(String? name) => PrinterLanguage.values
      .firstWhere((l) => l.name == name, orElse: () => PrinterLanguage.zpl);
}
