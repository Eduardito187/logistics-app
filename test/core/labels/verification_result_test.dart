import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/verification_result.dart';

// Enum del veredicto offline. isValid es true para valid (firmada OK) y open
// (etiqueta abierta, sin firma): ninguna de las dos se rechaza por firma.

void main() {
  group('VerificationResult.isValid', () {
    test('valid (firmada correcta) es aceptado', () {
      expect(VerificationResult.valid.isValid, isTrue);
    });

    test(
      'open (etiqueta abierta, k:0) es aceptado: no se rechaza por firma',
      () {
        expect(VerificationResult.open.isValid, isTrue);
      },
    );

    test('invalidSignature no es válido', () {
      expect(VerificationResult.invalidSignature.isValid, isFalse);
    });

    test('unknownKey no es válido', () {
      expect(VerificationResult.unknownKey.isValid, isFalse);
    });

    test('hay exactamente cuatro veredictos', () {
      expect(VerificationResult.values, hasLength(4));
    });
  });
}
