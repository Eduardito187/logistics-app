import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/signed_label.dart';

// Arma del cuerpo de `POST /app/labels/verify` desde un `SignedLabel`.
//
// Se apoya en el vector compartido con el backend (misma copia que usa
// label_test_vector_test): así el payload canónico y la firma son el contrato
// real y la prueba es determinista.

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('LabelScanner.buildVerifyRequest', () {
    test('arma payload canónico, keyId y firma desde el SignedLabel', () {
      final vector = _vector();
      final qrContent = vector['qr_content'] as String;
      final label = SignedLabel.fromQrContent(qrContent);

      final request = LabelScanner.buildVerifyRequest(label);

      // El payload es el mensaje canónico exacto que se firmó.
      expect(request.payload, vector['canonical']);
      expect(request.payload, label.payload.canonical());
      // El id de clave sale del campo "k" del QR.
      expect(request.keyId, vector['key_id']);
      // La firma va en base64url sin relleno, tal como viaja en el campo "s".
      final qr = jsonDecode(qrContent) as Map<String, dynamic>;
      expect(request.signature, qr['s']);
    });

    test('encodeSignature produce base64url sin relleno y reversible', () {
      final vector = _vector();
      final label = SignedLabel.fromQrContent(vector['qr_content'] as String);

      final encoded = LabelScanner.encodeSignature(label.signature);

      expect(encoded.contains('='), isFalse);
      expect(base64Url.decode(base64Url.normalize(encoded)), label.signature);
    });
  });
}
