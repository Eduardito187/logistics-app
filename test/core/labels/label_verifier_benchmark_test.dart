import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/labels/signed_label.dart';

// Benchmark simple de la verificación Ed25519 en Dart puro (`cryptography`
// sin plugin nativo). Sirve para decidir si conviene sacarla del isolate de UI:
// el costo medido acá (JIT de test) es una cota superior del de release (AOT).

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('verify: costo por escaneo y caché de resultados repetidos', () async {
    final vector = _vector();
    final verifier = LabelVerifier({
      vector['key_id'] as int: base64.decode(
        vector['public_key_base64'] as String,
      ),
    });
    final label = SignedLabel.fromQrContent(vector['qr_content'] as String);

    // Calentamiento (JIT) con etiquetas "distintas" para no pegar en la caché.
    for (var i = 0; i < 5; i++) {
      clearLabelVerifierCache(verifier);
      await verifier.verify(label);
    }

    const runs = 20;
    final cold = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      clearLabelVerifierCache(verifier);
      expect(await verifier.verify(label), VerificationResult.valid);
    }
    cold.stop();

    final warm = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      expect(await verifier.verify(label), VerificationResult.valid);
    }
    warm.stop();

    final coldMs = cold.elapsedMicroseconds / runs / 1000;
    final warmMs = warm.elapsedMicroseconds / runs / 1000;
    // ignore: avoid_print
    print(
      'Ed25519 verify: ${coldMs.toStringAsFixed(2)} ms/escaneo (sin caché), '
      '${warmMs.toStringAsFixed(3)} ms (repetido, con caché)',
    );
    // El repetido sale de la caché: mucho más barato que verificar.
    expect(warmMs, lessThan(coldMs));
    expect(labelVerifierCacheLength(verifier), 1);
  });

  test('la caché no cambia el veredicto de una etiqueta alterada', () async {
    final vector = _vector();
    final verifier = LabelVerifier({
      vector['key_id'] as int: base64.decode(
        vector['public_key_base64'] as String,
      ),
    });
    final good = SignedLabel.fromQrContent(vector['qr_content'] as String);
    final bad = SignedLabel.fromQrContent(
      vector['tampered_qr_content'] as String,
    );
    for (var i = 0; i < 3; i++) {
      expect(await verifier.verify(good), VerificationResult.valid);
      expect(await verifier.verify(bad), VerificationResult.invalidSignature);
    }
    expect(labelVerifierCacheLength(verifier), 2);
  });
}
