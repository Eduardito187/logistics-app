/// Error de impresión con mensaje claro para mostrar al operario (español).
///
/// [needsSetup] = el problema se arregla en Ajustes (no hay impresora elegida,
/// faltan credenciales…); la UI puede mandar al operario a configurarla.
class PrinterException implements Exception {
  const PrinterException(
    this.message, {
    this.needsSetup = false,
    this.cancelledAtDevice = false,
  });

  /// No hay impresora seleccionada.
  static const PrinterException notSelected = PrinterException(
    'No hay impresora seleccionada.',
    needsSetup: true,
  );

  final String message;
  final bool needsSetup;

  /// La impresora ACEPTÓ el trabajo pero lo canceló en el equipo
  /// (`job-canceled-at-device`): típico de Ricoh con autenticación de usuario
  /// por IPP. Señala que conviene reintentar por 9100 con el código de usuario.
  final bool cancelledAtDevice;

  @override
  String toString() => message;
}
