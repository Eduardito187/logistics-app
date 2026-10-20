import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_payload.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/labels/signed_label.dart';

// Verificación Ed25519 offline con claves generadas en el propio test (además
// del vector del backend, que cubre label_test_vector_test.dart). Fija la
// validación del constructor, parseConfig/fromConfig y el escenario de rotación
// (varias claves válidas a la vez).

LabelPayload _payload({required int keyId, String id = 'LBL-1'}) {
  return LabelPayload(
    version: LabelPayload.currentVersion,
    type: LabelType.package,
    keyId: keyId,
    id: id,
    orderNumber: 'DM-1',
    lineNumber: 1,
    sku: 'SKU-1',
    unit: Fraction(1, 2),
    piece: Fraction(1, 1),
    origin: 'CD01',
    destination: 'C',
    issuedAt: 1700000000,
  );
}

/// Firma el canónico del [payload] con [keyPair] y arma el SignedLabel.
Future<SignedLabel> _sign(LabelPayload payload, SimpleKeyPair keyPair) async {
  final algorithm = Ed25519();
  final signature = await algorithm.sign(
    utf8.encode(payload.canonical()),
    keyPair: keyPair,
  );
  return SignedLabel(payload, signature.bytes);
}

void main() {
  late Ed25519 algorithm;

  setUp(() => algorithm = Ed25519());

  group('LabelVerifier — validación del constructor', () {
    test('rechaza una clave pública que no mide 32 bytes', () {
      // Se valida ANTES de construir SimplePublicKey: el error es siempre el
      // propio, sin depender de lo que valide `cryptography` en su constructor.
      expect(
        () => LabelVerifier({1: List<int>.filled(16, 0)}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'La clave pública 1 debe tener 32 bytes.',
          ),
        ),
      );
    });

    test('rechaza aunque solo una de varias claves sea inválida', () {
      expect(
        () => LabelVerifier({
          1: List<int>.filled(32, 0),
          2: List<int>.filled(31, 0),
        }),
        throwsArgumentError,
      );
    });

    test('acepta un mapa vacío (no hay claves, pero no revienta)', () {
      expect(LabelVerifier(const <int, List<int>>{}), isA<LabelVerifier>());
    });
  });

  group('LabelVerifier.verify — con claves generadas', () {
    test(
      'una firma hecha con la clave privada correspondiente es válida',
      () async {
        final keyPair = await algorithm.newKeyPair();
        final publicKey = await keyPair.extractPublicKey();
        final label = await _sign(_payload(keyId: 7), keyPair);

        final verifier = LabelVerifier({7: publicKey.bytes});

        expect(await verifier.verify(label), VerificationResult.valid);
      },
    );

    test('una firma alterada se informa como invalidSignature', () async {
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final label = await _sign(_payload(keyId: 7), keyPair);
      final tampered = SignedLabel(
        label.payload,
        List<int>.of(label.signature)..[0] ^= 0xFF,
      );

      final verifier = LabelVerifier({7: publicKey.bytes});

      expect(
        await verifier.verify(tampered),
        VerificationResult.invalidSignature,
      );
    });

    test('un payload firmado con OTRA clave da invalidSignature', () async {
      final signingPair = await algorithm.newKeyPair();
      final otherPair = await algorithm.newKeyPair();
      final otherPublic = await otherPair.extractPublicKey();
      final label = await _sign(_payload(keyId: 7), signingPair);

      // El id de clave coincide (7) pero la clave pública es la equivocada.
      final verifier = LabelVerifier({7: otherPublic.bytes});

      expect(await verifier.verify(label), VerificationResult.invalidSignature);
    });

    test('una keyId ausente del bundle da unknownKey', () async {
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final label = await _sign(_payload(keyId: 7), keyPair);

      // El bundle solo tiene la clave 99: la 7 es desconocida.
      final verifier = LabelVerifier({99: publicKey.bytes});

      expect(await verifier.verify(label), VerificationResult.unknownKey);
    });

    test('rotación: ambas claves verifican sus propias etiquetas', () async {
      final oldPair = await algorithm.newKeyPair();
      final newPair = await algorithm.newKeyPair();
      final oldPublic = await oldPair.extractPublicKey();
      final newPublic = await newPair.extractPublicKey();

      final oldLabel = await _sign(_payload(keyId: 1), oldPair);
      final newLabel = await _sign(_payload(keyId: 2), newPair);

      final verifier = LabelVerifier({1: oldPublic.bytes, 2: newPublic.bytes});

      expect(await verifier.verify(oldLabel), VerificationResult.valid);
      expect(await verifier.verify(newLabel), VerificationResult.valid);
    });
  });

  group('LabelVerifier.parseConfig', () {
    test('parsea varias entradas "id:base64" separadas por coma', () {
      final b64 = base64.encode(List<int>.filled(32, 1));
      final parsed = LabelVerifier.parseConfig('1:$b64, 2:$b64');

      expect(parsed.keys, containsAll(<int>[1, 2]));
      expect(parsed[1], hasLength(32));
    });

    test('ignora entradas vacías entre comas', () {
      final b64 = base64.encode(List<int>.filled(32, 1));
      final parsed = LabelVerifier.parseConfig('1:$b64,,');

      expect(parsed.keys, <int>[1]);
    });

    test('lanza ArgumentError si falta el ":" (id)', () {
      expect(
        () => LabelVerifier.parseConfig('sin-separador'),
        throwsArgumentError,
      );
    });

    test('lanza ArgumentError si el id no es entero', () {
      final b64 = base64.encode(List<int>.filled(32, 1));
      expect(() => LabelVerifier.parseConfig('abc:$b64'), throwsArgumentError);
    });

    test('lanza ArgumentError si el separador está al inicio', () {
      final b64 = base64.encode(List<int>.filled(32, 1));
      expect(() => LabelVerifier.parseConfig(':$b64'), throwsArgumentError);
    });
  });

  group('LabelVerifier.fromConfig', () {
    test(
      'construye un verificador funcional desde el string de config',
      () async {
        final keyPair = await algorithm.newKeyPair();
        final publicKey = await keyPair.extractPublicKey();
        final label = await _sign(_payload(keyId: 5), keyPair);
        final b64 = base64.encode(publicKey.bytes);

        final verifier = LabelVerifier.fromConfig('5:$b64');

        expect(await verifier.verify(label), VerificationResult.valid);
      },
    );
  });
}
