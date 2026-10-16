import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_payload.dart';
import 'package:logistics_app/core/printing/zpl_builder.dart';

// Complementa zpl_builder_test.dart: estructura ZPL (comandos de formato),
// símbolo explícito LabelSymbology.qr, destino de nodo (no cliente) y que el
// QR lleve el JSON firmado exacto mientras el Code128 lleva el id corto.

LabelPayload _payload({String destination = 'NODE-7'}) {
  return LabelPayload(
    version: LabelPayload.currentVersion,
    type: LabelType.package,
    keyId: 3,
    id: 'LBL-42',
    orderNumber: 'DM-260012345',
    lineNumber: 7,
    sku: 'SKU-9',
    unit: Fraction(1, 2),
    piece: Fraction(2, 3),
    origin: 'CD01',
    destination: destination,
    issuedAt: 1700000000,
  );
}

void main() {
  const qr = '{"v":1,"t":"PKG","sig":"abc"}';

  group('ZplBuilder.packageLabel — estructura ZPL', () {
    test('incluye los comandos de formato de la ZQ630', () {
      final zpl = ZplBuilder.packageLabel(payload: _payload(), qrContent: qr);

      expect(zpl, contains('^CI28')); // UTF-8
      expect(zpl, contains('^PW812')); // ancho ~100 mm
      expect(zpl, contains('^LL609'));
      expect(zpl, contains('^LH0,0'));
    });

    test('las líneas se separan con salto de línea', () {
      final zpl = ZplBuilder.packageLabel(payload: _payload(), qrContent: qr);
      expect(zpl.split('\n').first, '^XA');
      expect(zpl.split('\n').last, '^XZ');
    });
  });

  group('ZplBuilder.packageLabel — destino', () {
    test('muestra el código de nodo crudo cuando NO es del cliente', () {
      final zpl = ZplBuilder.packageLabel(
        payload: _payload(destination: 'NODE-7'),
        qrContent: qr,
      );
      expect(zpl, contains('CD01 -> NODE-7'));
      expect(zpl, isNot(contains('CLIENTE')));
    });
  });

  group('ZplBuilder.packageLabel — símbolos', () {
    test('LabelSymbology.qr explícito: solo QR, con el JSON firmado', () {
      final zpl = ZplBuilder.packageLabel(
        payload: _payload(),
        qrContent: qr,
        symbology: LabelSymbology.qr,
      );
      expect(zpl, contains('^FDLA,$qr^FS'));
      expect(zpl, isNot(contains('^BCN')));
    });

    test('el QR lleva el JSON firmado y el Code128 el id corto (both)', () {
      final zpl = ZplBuilder.packageLabel(
        payload: _payload(),
        qrContent: qr,
        symbology: LabelSymbology.both,
      );
      // QR: payload completo firmado.
      expect(zpl, contains('^FDLA,$qr^FS'));
      // Code128: solo el id corto del bulto, NO el JSON.
      expect(zpl, contains('^FO30,450^BCN,80,Y,N,N^FDLBL-42^FS'));
    });

    test('barcode-only no incluye el JSON firmado en ningún lado', () {
      final zpl = ZplBuilder.packageLabel(
        payload: _payload(),
        qrContent: qr,
        symbology: LabelSymbology.barcode,
      );
      expect(zpl, isNot(contains(qr)));
      expect(zpl, contains('^FDLBL-42^FS'));
    });
  });

  group('ZplBuilder.packageLabel — datos del bulto', () {
    test('imprime unidad y pieza con el formato N/M', () {
      final zpl = ZplBuilder.packageLabel(payload: _payload(), qrContent: qr);
      expect(zpl, contains('U 1/2'));
      expect(zpl, contains('Pza 2/3'));
    });
  });
}
