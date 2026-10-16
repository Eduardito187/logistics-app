import '../labels/label_payload.dart';
import 'label_symbology.dart';

// Se reexporta [LabelSymbology] (movido a su propio archivo por SRP) para no
// romper a quienes importan `printing/zpl_builder.dart`.
export 'label_symbology.dart';

/// Construye ZPL para la Zebra ZQ630 (203 dpi, etiqueta ~100x75 mm).
///
/// La ruta principal de impresión trae el ZPL ya firmado del backend
/// (`/app/orders/{orderNumber}/labels/zpl`). Este builder es para previsualizar
/// y para reimprimir una etiqueta ya verificada en terreno sin red.
abstract final class ZplBuilder {
  const ZplBuilder._();

  /// Etiqueta de una unidad (tipo PKG) con QR firmado y/o Code128 + texto.
  ///
  /// [qrContent] es el JSON firmado exacto que va en el QR. [symbology] elige
  /// qué símbolos se imprimen; por defecto [LabelSymbology.qr] para conservar
  /// el layout histórico (el QR firmado es el canónico que se verifica offline;
  /// el Code128 es opt-in porque suma alto en una etiqueta ya ajustada).
  static String packageLabel({
    required LabelPayload payload,
    required String qrContent,
    LabelSymbology symbology = LabelSymbology.qr,
  }) {
    final destination = payload.isForCustomer ? 'CLIENTE' : payload.destination;
    final includeQr =
        symbology == LabelSymbology.qr || symbology == LabelSymbology.both;
    final includeBarcode =
        symbology == LabelSymbology.barcode || symbology == LabelSymbology.both;
    return [
      '^XA',
      '^CI28', // UTF-8
      '^PW812', // ancho ~100 mm a 203 dpi
      '^LL609',
      '^LH0,0',
      // QR firmado (payload completo, se verifica offline)
      if (includeQr) '^FO30,30^BQN,2,6^FDLA,$qrContent^FS',
      // Pedido y SKU
      '^FO340,40^A0N,40,40^FDPedido ${payload.orderNumber}^FS',
      '^FO340,90^A0N,34,34^FDSKU ${payload.sku}^FS',
      '^FO340,135^A0N,30,30^FDLinea ${payload.lineNumber}^FS',
      // Unidad N/M y pieza
      '^FO340,185^A0N,46,46^FDU ${payload.unit.toCanonical()}'
          '  Pza ${payload.piece.toCanonical()}^FS',
      // Origen -> destino
      '^FO30,330^A0N,40,40^FD${payload.origin} -> $destination^FS',
      // Id corto para lectura humana
      '^FO30,400^A0N,28,28^FDID ${payload.id}^FS',
      // Code128 secundario con el id corto del bulto (legible por lector 1D)
      if (includeBarcode) '^FO30,450^BCN,80,Y,N,N^FD${payload.id}^FS',
      '^XZ',
    ].join('\n');
  }
}
