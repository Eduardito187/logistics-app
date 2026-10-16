import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_format_exception.dart';
import 'package:logistics_app/core/labels/label_payload.dart';

// Lógica pura del payload de etiqueta (sin firma): fracciones, tipos y el
// mensaje canónico. El canónico byte a byte contra el backend lo cubre el
// vector compartido; aquí se prueban las reglas de construcción.

LabelPayload _payload({
  String id = 'LBL-1',
  String orderNumber = 'DM-260012345',
  int lineNumber = 1,
  String sku = 'SKU-9',
  Fraction? unit,
  Fraction? piece,
  String origin = 'CD01',
  String destination = 'NODE-7',
  int issuedAt = 1700000000,
}) {
  return LabelPayload(
    version: LabelPayload.currentVersion,
    type: LabelType.package,
    keyId: 3,
    id: id,
    orderNumber: orderNumber,
    lineNumber: lineNumber,
    sku: sku,
    unit: unit ?? Fraction(1, 2),
    piece: piece ?? Fraction(1, 1),
    origin: origin,
    destination: destination,
    issuedAt: issuedAt,
  );
}

void main() {
  group('Fraction', () {
    test('toCanonical usa el formato N/M', () {
      expect(Fraction(1, 2).toCanonical(), '1/2');
      expect(Fraction(3, 3).toCanonical(), '3/3');
    });

    test('la igualdad y el hashCode comparan índice y total', () {
      expect(Fraction(1, 2), Fraction(1, 2));
      expect(Fraction(1, 2).hashCode, Fraction(1, 2).hashCode);
      expect(Fraction(1, 2) == Fraction(2, 2), isFalse);
    });

    test('rechaza un total fuera de 1..999', () {
      expect(() => Fraction(1, 0), throwsA(isA<LabelFormatException>()));
      expect(() => Fraction(1, 1000), throwsA(isA<LabelFormatException>()));
    });

    test('rechaza un índice fuera de 1..total', () {
      expect(() => Fraction(0, 2), throwsA(isA<LabelFormatException>()));
      expect(() => Fraction(3, 2), throwsA(isA<LabelFormatException>()));
    });
  });

  group('LabelType.fromCode', () {
    test('resuelve cada código conocido', () {
      expect(LabelType.fromCode('PKG'), LabelType.package);
      expect(LabelType.fromCode('MAN'), LabelType.manifest);
      expect(LabelType.fromCode('NOD'), LabelType.node);
      expect(LabelType.fromCode('VEH'), LabelType.vehicle);
      expect(LabelType.fromCode('DLV'), LabelType.delivery);
    });

    test('devuelve null para un código desconocido', () {
      expect(LabelType.fromCode('XXX'), isNull);
      expect(LabelType.fromCode('pkg'), isNull); // sensible a mayúsculas
    });
  });

  group('LabelPayload', () {
    test('canonical arma el mensaje con el separador | en orden', () {
      final payload = _payload();

      expect(
        payload.canonical(),
        'LGL|1|PKG|3|LBL-1|DM-260012345|1|SKU-9|1/2|1/1|CD01|NODE-7|1700000000',
      );
    });

    test('isForCustomer es true solo cuando el destino es el cliente', () {
      expect(_payload(destination: 'C').isForCustomer, isTrue);
      expect(_payload(destination: 'NODE-7').isForCustomer, isFalse);
    });
  });
}
