/// Transporte físico por el que se habla con la impresora de etiquetas.
///
/// Las Zebra portátiles del flujo (ZQ630 Plus) hablan ZPL crudo por cualquiera
/// de los tres: Bluetooth (en terreno), WiFi (impresora de red en andén) y USB
/// (cable directo a la tablet). El ZPL que se envía es idéntico en los tres.
enum PrinterTransport {
  bluetooth('Bluetooth'),
  wifi('WiFi'),
  usb('USB');

  const PrinterTransport(this.label);

  /// Etiqueta legible para la UI (español).
  final String label;

  static PrinterTransport fromName(String name) {
    return PrinterTransport.values.firstWhere(
      (t) => t.name == name,
      orElse: () => PrinterTransport.bluetooth,
    );
  }
}
