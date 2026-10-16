import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_format_exception.dart';
import 'package:logistics_app/core/labels/label_payload.dart';
import 'package:logistics_app/core/labels/signed_label.dart';

// Parseo del QR a [SignedLabel]. label_test_vector_test.dart ya prueba el
// camino feliz con el vector y algunos inválidos; aquí se cubre field por field
// la validación de tipos, las fracciones mal formadas, la firma base64url y la
// longitud de 64 bytes, además de la inmutabilidad de la firma.

/// Base válida mínima para un QR PKG v1. La firma "s" es un base64url de 64
/// bytes SIN relleno (como viaja en el campo "s"), reversible y con longitud
/// exacta: así el parseo llega hasta el final. Se calcula para no depender de
/// contar caracteres a mano.
final String _validSignature = base64Url
    .encode(List<int>.filled(SignedLabel.signatureBytes, 0))
    .replaceAll('=', '');

Map<String, dynamic> _baseMap() => <String, dynamic>{
  'v': 1,
  't': 'PKG',
  'k': 1,
  'id': 'LBL-1',
  'o': 'DM-1',
  'ln': 2,
  'sku': 'SKU-1',
  'u': <int>[1, 2],
  'pc': <int>[1, 1],
  'org': 'CD01',
  'dst': 'C',
  'ts': 1700000000,
  's': _validSignature,
};

String _qr(Map<String, dynamic> overrides) {
  final map = _baseMap()..addAll(overrides);
  return jsonEncode(map);
}

void main() {
  group('SignedLabel — constante de longitud', () {
    test('la firma Ed25519 mide 64 bytes', () {
      expect(SignedLabel.signatureBytes, 64);
    });
  });

  group('SignedLabel.fromQrContent — camino válido', () {
    test('la firma válida decodifica a 64 bytes', () {
      final label = SignedLabel.fromQrContent(_qr({}));
      expect(label.signature, hasLength(64));
    });

    test('expone todos los campos del payload', () {
      final label = SignedLabel.fromQrContent(
        _qr({'k': 9, 'id': 'X9', 'ln': 7, 'sku': 'S9', 'ts': 42, 'org': 'A'}),
      );

      expect(label.payload.version, LabelPayload.currentVersion);
      expect(label.payload.type, LabelType.package);
      expect(label.payload.keyId, 9);
      expect(label.payload.id, 'X9');
      expect(label.payload.lineNumber, 7);
      expect(label.payload.sku, 'S9');
      expect(label.payload.issuedAt, 42);
      expect(label.payload.origin, 'A');
      expect(label.payload.piece.toCanonical(), '1/1');
    });

    test('la firma es inmutable', () {
      final label = SignedLabel.fromQrContent(_qr({}));
      expect(() => label.signature.add(0), throwsUnsupportedError);
    });
  });

  group('SignedLabel.fromQrContent — formato general', () {
    test('rechaza contenido que no es JSON', () {
      expect(
        () => SignedLabel.fromQrContent('no-json'),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza un JSON que no es objeto (lista)', () {
      expect(
        () => SignedLabel.fromQrContent('[1,2,3]'),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza un JSON que no es objeto (número)', () {
      expect(
        () => SignedLabel.fromQrContent('42'),
        throwsA(isA<LabelFormatException>()),
      );
    });
  });

  group('SignedLabel.fromQrContent — versión y tipo', () {
    test('rechaza una versión distinta de 1', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'v': 2})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "v" que no es entero', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'v': '1'})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza un tipo distinto de PKG aunque sea conocido', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'t': 'VEH'})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza un código de tipo desconocido', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'t': 'ZZZ'})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "t" que no es texto', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'t': 5})),
        throwsA(isA<LabelFormatException>()),
      );
    });
  });

  group('SignedLabel.fromQrContent — tipos por campo', () {
    test('rechaza "k" no entero', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'k': 'x'})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "id" no texto', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'id': 10})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "o" (orderNumber) no texto', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'o': 10})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "ln" no entero', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'ln': 'x'})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "sku" no texto', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'sku': 1})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "org" no texto', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'org': 1})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "dst" no texto', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'dst': 1})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "ts" no entero', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'ts': '1'})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza un campo faltante', () {
      final map = _baseMap()..remove('sku');
      expect(
        () => SignedLabel.fromQrContent(jsonEncode(map)),
        throwsA(isA<LabelFormatException>()),
      );
    });
  });

  group('SignedLabel.fromQrContent — fracciones', () {
    test('rechaza "u" que no es lista', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'u': '1/2'})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "u" con longitud distinta de 2', () {
      expect(
        () => SignedLabel.fromQrContent(
          _qr({
            'u': <int>[1],
          }),
        ),
        throwsA(isA<LabelFormatException>()),
      );
      expect(
        () => SignedLabel.fromQrContent(
          _qr({
            'u': <int>[1, 2, 3],
          }),
        ),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "u" con elementos no enteros', () {
      expect(
        () => SignedLabel.fromQrContent(
          _qr({
            'u': <dynamic>['1', '2'],
          }),
        ),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza "pc" con fracción fuera de rango (propaga Fraction)', () {
      // index > total: Fraction lanza LabelFormatException al construir.
      expect(
        () => SignedLabel.fromQrContent(
          _qr({
            'pc': <int>[5, 2],
          }),
        ),
        throwsA(isA<LabelFormatException>()),
      );
    });
  });

  group('SignedLabel.fromQrContent — firma', () {
    test('rechaza una firma fuera del alfabeto base64url', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'s': 'abc+def/='})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza una firma vacía', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'s': ''})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza una firma que no es texto', () {
      expect(
        () => SignedLabel.fromQrContent(_qr({'s': 123})),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('rechaza una firma base64url válida que no mide 64 bytes', () {
      // "AAAA" es base64url válido pero decodifica a 3 bytes: el constructor
      // de SignedLabel exige 64.
      expect(
        () => SignedLabel.fromQrContent(_qr({'s': 'AAAA'})),
        throwsA(
          isA<LabelFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('64'),
          ),
        ),
      );
    });

    test('acepta firma base64url con - y _ (sin relleno)', () {
      // Reemplaza algunos bytes por un patrón que produce - y _ en base64url.
      final label = SignedLabel.fromQrContent(
        _qr({
          's': 'vGUuqT7zusA-xPjt0iW0TSy6i8F5QojH3ajEFLQ5b3Mf5ze9QOzTT1MHCk-9QnWYil2H5Hj9cBcC2awgauFADw',
        }),
      );
      expect(label.signature, hasLength(64));
    });
  });

  group('SignedLabel — constructor directo', () {
    test('rechaza una firma de longitud distinta de 64', () {
      final label = SignedLabel.fromQrContent(_qr({}));
      expect(
        () => SignedLabel(label.payload, List<int>.filled(10, 0)),
        throwsA(isA<LabelFormatException>()),
      );
    });

    test('acepta exactamente 64 bytes', () {
      final label = SignedLabel.fromQrContent(_qr({}));
      final rebuilt = SignedLabel(label.payload, List<int>.filled(64, 1));
      expect(rebuilt.signature, hasLength(64));
    });
  });
}
