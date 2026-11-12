import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/zebra_status.dart';

// Estado de la Zebra leído por 9100 tras imprimir (~HS y ~HQES).

const _stx = '\x02';
const _etx = '\x03';

String _hs(String line1, String line2) =>
    '$_stx$line1$_etx\r\n$_stx$line2$_etx\r\n${_stx}1234,0$_etx\r\n';

void main() {
  group('~HS', () {
    test('sin errores → lista', () {
      final status = ZebraStatus.parse(
        _hs(
          '030,0,0,0245,000,0,0,0,000,0,0,0',
          '001,0,0,0,1,2,6,0,00000000,1,000',
        ),
      )!;
      expect(status.hasProblem, isFalse);
      expect(status.problemMessage, isNull);
    });

    test('papel agotado y cabezal abierto', () {
      final status = ZebraStatus.parse(
        _hs(
          '030,1,0,0245,000,0,0,0,000,0,0,0',
          '001,0,1,0,1,2,6,0,00000000,1,000',
        ),
      )!;
      expect(status.paperOut, isTrue);
      expect(status.headOpen, isTrue);
      expect(status.paused, isFalse);
      expect(
        status.problemMessage,
        'La impresora está sin etiquetas/papel, con el cabezal abierto. La '
        'etiqueta quedó en espera: resolvelo y saldrá.',
      );
    });

    test('en pausa y sin cinta', () {
      final status = ZebraStatus.parse(
        _hs(
          '030,0,1,0245,000,0,0,0,000,0,0,0',
          '001,0,0,1,1,2,6,0,00000000,1,000',
        ),
      )!;
      expect(status.paused, isTrue);
      expect(status.ribbonOut, isTrue);
      expect(status.problemMessage, contains('sin cinta, en pausa'));
    });
  });

  group('~HQES', () {
    test('ERRORS 0 → lista', () {
      final status = ZebraStatus.parse(
        '$_stx\r\n  PRINTER STATUS\r\n'
        '   ERRORS:         0 00000000 00000000\r\n'
        '   WARNINGS:       0 00000000 00000000\r\n$_etx',
      )!;
      expect(status.hasProblem, isFalse);
    });

    test('máscara 5 = sin papel + cabezal abierto', () {
      final status = ZebraStatus.parse(
        '$_stx\r\n  PRINTER STATUS\r\n'
        '   ERRORS:         1 00000000 00000005\r\n'
        '   WARNINGS:       0 00000000 00000000\r\n$_etx',
      )!;
      expect(status.paperOut, isTrue);
      expect(status.headOpen, isTrue);
      expect(status.ribbonOut, isFalse);
      expect(status.otherError, isFalse);
    });

    test('otro bit (cortador) → error genérico', () {
      final status = ZebraStatus.parse(
        '   ERRORS:         1 00000000 00000008\r\n',
      )!;
      expect(status.otherError, isTrue);
      expect(status.problemMessage, contains('con un error'));
    });
  });

  test('respuesta que no es de estado → null', () {
    expect(ZebraStatus.parse('hola'), isNull);
    expect(ZebraStatus.parse(''), isNull);
  });
}
