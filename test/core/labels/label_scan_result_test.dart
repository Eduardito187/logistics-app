import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/label_verification.dart';
import 'package:logistics_app/core/api/models/label_verification_result.dart';
import 'package:logistics_app/core/labels/label_scan_result.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/labels/signed_label.dart';

// [LabelScanResult] combina el veredicto offline (el que manda) con el
// contrahecheo opcional del backend. isValid SIEMPRE sigue al offline.

SignedLabel _label() => SignedLabel.fromQrContent(
  (jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
          as Map<String, dynamic>)['qr_content']
      as String,
);

void main() {
  group('LabelScanResult', () {
    test('isValid sigue al veredicto offline valid', () {
      final result = LabelScanResult(
        label: _label(),
        verification: VerificationResult.valid,
      );
      expect(result.isValid, isTrue);
      expect(result.backendVerification, isNull);
    });

    test('isValid es false cuando el offline es invalidSignature', () {
      final result = LabelScanResult(
        label: _label(),
        verification: VerificationResult.invalidSignature,
      );
      expect(result.isValid, isFalse);
    });

    test('isValid es false cuando el offline es unknownKey', () {
      final result = LabelScanResult(
        label: _label(),
        verification: VerificationResult.unknownKey,
      );
      expect(result.isValid, isFalse);
    });

    test(
      'backendVerification se adjunta sin cambiar isValid (offline manda)',
      () {
        // Offline válido pero el backend dice inválido: la decisión en terreno
        // sigue siendo la offline (isValid true).
        final result = LabelScanResult(
          label: _label(),
          verification: VerificationResult.valid,
          backendVerification: const LabelVerification(
            valid: false,
            result: LabelVerificationResult.invalidSignature,
          ),
        );

        expect(result.isValid, isTrue);
        expect(result.backendVerification, isNotNull);
        expect(result.backendVerification!.valid, isFalse);
      },
    );
  });
}
