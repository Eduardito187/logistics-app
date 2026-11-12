/// Pasos del asistente "Conectar impresora" (una decisión por paso).
enum PrinterSetupStep {
  /// "¿Cómo se conecta?": Bluetooth / WiFi / Cable USB.
  transport(1, '¿Cómo se conecta?'),

  /// Elegir la impresora (lista o búsqueda en la red).
  choose(2, 'Elegí tu impresora'),

  /// Listo: confirmación, acceso si hace falta y prueba.
  done(3, 'Listo');

  const PrinterSetupStep(this.number, this.title);

  /// Número visible ("Paso 2 de 3").
  final int number;

  /// Título del paso (español).
  final String title;

  static const int count = 3;
}
