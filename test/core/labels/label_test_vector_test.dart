import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_format_exception.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/labels/signed_label.dart';

// El vector es el contrato con el backend: copia idéntica de
// logistics/packages/logistics/labels/tests/Fixtures/label-test-vector.json.
// Si estos tests fallan, el formato de firma cambió en un lado y no en el otro.

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

LabelVerifier _verifier(Map<String, dynamic> vector) => LabelVerifier({
  vector['key_id'] as int: base64.decode(vector['public_key_base64'] as String),
});

void main() {
  group('vector compartido con el backend', () {
    test('el mensaje canónico coincide byte a byte con el del backend', () {
      final vector = _vector();
      final label = SignedLabel.fromQrContent(vector['qr_content'] as String);

      expect(label.payload.canonical(), vector['canonical']);
    });

    test('la firma generada por el backend verifica en la app', () async {
      final vector = _vector();
      final label = SignedLabel.fromQrContent(vector['qr_content'] as String);

      expect(await _verifier(vector).verify(label), VerificationResult.valid);
    });

    test('una etiqueta editada después de firmada se rechaza', () async {
      final vector = _vector();
      final label = SignedLabel.fromQrContent(
        vector['tampered_qr_content'] as String,
      );

      expect(
        await _verifier(vector).verify(label),
        VerificationResult.invalidSignature,
      );
    });

    test('una clave desconocida se informa como tal', () async {
      final vector = _vector();
      final label = SignedLabel.fromQrContent(vector['qr_content'] as String);
      final verifier = LabelVerifier({99: List<int>.filled(32, 7)});

      expect(await verifier.verify(label), VerificationResult.unknownKey);
    });
  });

  group('lectura del QR', () {
    test('expone los datos del bulto', () {
      final label = SignedLabel.fromQrContent(
        _vector()['qr_content'] as String,
      );

      expect(label.payload.orderNumber, 'DM-260012345');
      expect(label.payload.unit.toCanonical(), '1/2');
      expect(label.payload.isForCustomer, isTrue);
    });

    for (final (name, content) in [
      ('no es JSON', 'hola'),
      ('no es un objeto', '42'),
      ('versión no soportada', '{"v":2,"t":"PKG"}'),
      ('tipo aún no implementado', '{"v":1,"t":"VEH"}'),
      ('faltan campos', '{"v":1,"t":"PKG","k":1}'),
    ]) {
      test('rechaza contenido inválido: $name', () {
        expect(
          () => SignedLabel.fromQrContent(content),
          throwsA(isA<LabelFormatException>()),
        );
      });
    }

    test('lee claves públicas con el mismo formato que el backend', () async {
      final vector = _vector();
      final verifier = LabelVerifier.fromConfig(
        '${vector['key_id']}:${vector['public_key_base64']}',
      );
      final label = SignedLabel.fromQrContent(vector['qr_content'] as String);

      expect(await verifier.verify(label), VerificationResult.valid);
    });
  });
}
