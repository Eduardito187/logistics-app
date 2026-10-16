import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_payload.dart';
import 'package:logistics_app/core/printing/zpl_builder.dart';

// La etiqueta reimpresa en terreno debe contener el QR firmado y el texto
// legible, y abrir/cerrar el formato ZPL. No validamos cada coordenada,
// solo que los datos del bulto estén presentes y el formato sea correcto.

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
  group('ZplBuilder.packageLabel', () {
    const qr = '{"v":1,"t":"PKG","sig":"abc"}';

    test('abre y cierra el formato ZPL', () {
      final zpl = ZplBuilder.packageLabel(payload: _payload(), qrContent: qr);

      expect(zpl, startsWith('^XA'));
      expect(zpl, endsWith('^XZ'));
    });

    test('incluye el QR firmado con el código ^BQ', () {
      final zpl = ZplBuilder.packageLabel(payload: _payload(), qrContent: qr);

      expect(zpl, contains('^BQN'));
      expect(zpl, contains('^FDLA,$qr^FS'));
    });

    test('imprime pedido, SKU, línea, origen y destino', () {
      final zpl = ZplBuilder.packageLabel(payload: _payload(), qrContent: qr);

      expect(zpl, contains('Pedido DM-260012345'));
      expect(zpl, contains('SKU SKU-9'));
      expect(zpl, contains('Linea 7'));
      expect(zpl, contains('CD01 -> NODE-7'));
      expect(zpl, contains('U 1/2'));
      expect(zpl, contains('Pza 2/3'));
      expect(zpl, contains('ID LBL-42'));
    });

    test('muestra CLIENTE como destino cuando la etiqueta es del cliente', () {
      final zpl = ZplBuilder.packageLabel(
        payload: _payload(destination: LabelPayload.customerDestination),
        qrContent: qr,
      );

      expect(zpl, contains('CD01 -> CLIENTE'));
    });

    test('por defecto solo lleva QR, sin código de barras Code128', () {
      final zpl = ZplBuilder.packageLabel(payload: _payload(), qrContent: qr);

      expect(zpl, contains('^BQN'));
      expect(zpl, isNot(contains('^BCN')));
    });

    test('con symbology both agrega Code128 con el id corto del bulto', () {
      final zpl = ZplBuilder.packageLabel(
        payload: _payload(),
        qrContent: qr,
        symbology: LabelSymbology.both,
      );

      expect(zpl, contains('^BQN'));
      expect(zpl, contains('^BCN'));
      expect(zpl, contains('^FDLBL-42^FS'));
    });

    test('con symbology barcode lleva Code128 y no lleva QR', () {
      final zpl = ZplBuilder.packageLabel(
        payload: _payload(),
        qrContent: qr,
        symbology: LabelSymbology.barcode,
      );

      expect(zpl, contains('^BCN'));
      expect(zpl, isNot(contains('^BQN')));
    });
  });
}
