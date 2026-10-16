import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_payload.dart';

// Complementa label_payload_test.dart: constantes del contrato y variantes del
// mensaje canónico (destino cliente, otras fracciones, tipo no-PKG) que el test
// existente no cubre. El canónico byte a byte contra el backend lo valida
// label_test_vector_test.dart con el vector compartido.

LabelPayload _payload({
  int version = LabelPayload.currentVersion,
  LabelType type = LabelType.package,
  int keyId = 3,
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
    version: version,
    type: type,
    keyId: keyId,
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
  group('LabelPayload — constantes del contrato', () {
    test('la versión actual es 1', () {
      expect(LabelPayload.currentVersion, 1);
    });

    test('el destino cliente final es "C"', () {
      expect(LabelPayload.customerDestination, 'C');
    });
  });

  group('LabelPayload.canonical — variantes', () {
    test('usa "C" como destino cuando la etiqueta es para el cliente', () {
      final canonical = _payload(destination: 'C').canonical();

      // El canónico lleva el código de nodo crudo ("C"), NO la palabra CLIENTE
      // (eso es solo para imprimir, ver ZplBuilder).
      expect(canonical.endsWith('|C|1700000000'), isTrue);
    });

    test('refleja las fracciones de unidad y pieza en formato N/M', () {
      final canonical = _payload(
        unit: Fraction(2, 4),
        piece: Fraction(3, 5),
      ).canonical();

      expect(canonical, contains('|2/4|3/5|'));
    });

    test('usa el código del tipo, no su nombre de enum', () {
      final canonical = _payload(type: LabelType.manifest).canonical();

      expect(canonical, contains('|MAN|'));
      expect(canonical, isNot(contains('manifest')));
    });

    test('empieza con el prefijo LGL y la versión', () {
      expect(_payload().canonical(), startsWith('LGL|1|PKG|'));
    });

    test('tiene exactamente 13 campos separados por |', () {
      expect(_payload().canonical().split('|'), hasLength(13));
    });
  });

  group('LabelPayload.isForCustomer', () {
    test('es true solo con el destino "C" exacto', () {
      expect(_payload(destination: 'C').isForCustomer, isTrue);
      expect(_payload(destination: 'c').isForCustomer, isFalse);
      expect(_payload(destination: 'CLIENTE').isForCustomer, isFalse);
      expect(_payload(destination: '').isForCustomer, isFalse);
    });
  });
}
