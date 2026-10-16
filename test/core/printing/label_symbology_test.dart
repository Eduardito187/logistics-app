import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/label_symbology.dart';

// Enum de símbolos de la etiqueta. El comportamiento por branch (qué comandos
// ZPL incluye cada valor) se prueba en zpl_builder_test.dart y
// zpl_builder_commands_test.dart; aquí solo se fija el contrato del enum.

void main() {
  group('LabelSymbology', () {
    test('tiene exactamente tres variantes', () {
      expect(LabelSymbology.values, hasLength(3));
    });

    test('expone qr, barcode y both', () {
      expect(LabelSymbology.values, <LabelSymbology>[
        LabelSymbology.qr,
        LabelSymbology.barcode,
        LabelSymbology.both,
      ]);
    });
  });
}
