import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/verification_result.dart';

// Enum del veredicto offline. isValid es true SOLO para valid.

void main() {
  group('VerificationResult.isValid', () {
    test('valid es el único veredicto aceptado', () {
      expect(VerificationResult.valid.isValid, isTrue);
    });

    test('invalidSignature no es válido', () {
      expect(VerificationResult.invalidSignature.isValid, isFalse);
    });

    test('unknownKey no es válido', () {
      expect(VerificationResult.unknownKey.isValid, isFalse);
    });

    test('hay exactamente tres veredictos', () {
      expect(VerificationResult.values, hasLength(3));
    });
  });
}
