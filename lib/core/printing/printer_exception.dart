/// Error de impresión con mensaje claro para mostrar al operario (español).
class PrinterException implements Exception {
  const PrinterException(this.message);
  final String message;
  @override
  String toString() => message;
}
