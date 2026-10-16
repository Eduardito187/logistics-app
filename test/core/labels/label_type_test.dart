import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_type.dart';

// Contrato de códigos de [LabelType] con el backend. label_payload_test.dart ya
// cubre fromCode con códigos conocidos/desconocidos; aquí se fija el código de
// cada valor (el string que viaja en el campo "t") y los bordes de fromCode.

void main() {
  group('LabelType.code', () {
    test('cada valor expone su código del contrato', () {
      expect(LabelType.package.code, 'PKG');
      expect(LabelType.manifest.code, 'MAN');
      expect(LabelType.node.code, 'NOD');
      expect(LabelType.vehicle.code, 'VEH');
      expect(LabelType.delivery.code, 'DLV');
    });

    test('hay exactamente cinco tipos conocidos', () {
      expect(LabelType.values, hasLength(5));
    });
  });

  group('LabelType.fromCode', () {
    test('es una ida y vuelta para cada valor', () {
      for (final type in LabelType.values) {
        expect(LabelType.fromCode(type.code), type);
      }
    });

    test('devuelve null para un código vacío', () {
      expect(LabelType.fromCode(''), isNull);
    });

    test('es sensible a mayúsculas y a espacios', () {
      expect(LabelType.fromCode('pkg'), isNull);
      expect(LabelType.fromCode(' PKG'), isNull);
      expect(LabelType.fromCode('PKG '), isNull);
    });
  });
}
