import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_format_exception.dart';

// La excepción de formato de etiqueta: conserva la razón y la muestra con un
// prefijo legible para el operario.

void main() {
  group('LabelFormatException', () {
    test('guarda la razón tal cual', () {
      final exception = LabelFormatException('faltan campos');
      expect(exception.reason, 'faltan campos');
    });

    test('toString antepone "Etiqueta inválida:"', () {
      expect(
        LabelFormatException('no es JSON').toString(),
        'Etiqueta inválida: no es JSON',
      );
    });

    test('es una Exception', () {
      expect(LabelFormatException('x'), isA<Exception>());
    });
  });
}
