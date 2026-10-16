import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/printer_exception.dart';

// Error de impresión: su toString ES el mensaje (sin prefijo), para mostrarlo
// tal cual en un SnackBar al operario.

void main() {
  group('PrinterException', () {
    test('conserva el mensaje', () {
      const exception = PrinterException('No hay impresora seleccionada.');
      expect(exception.message, 'No hay impresora seleccionada.');
    });

    test('toString devuelve el mensaje tal cual', () {
      expect(
        const PrinterException('Sin IP configurada.').toString(),
        'Sin IP configurada.',
      );
    });

    test('es una Exception', () {
      expect(const PrinterException('x'), isA<Exception>());
    });
  });
}
