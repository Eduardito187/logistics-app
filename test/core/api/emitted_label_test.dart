import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/emitted_label.dart';

// Etiquetas GLOBALES y PERMANENTES: el backend ya NO manda `revoked` en
// `GET /app/orders/{n}/labels`. Con el campo como REQUERIDO el parseo
// explotaba y el pedido no cargaba ("No se pudo cargar") — regresión real
// vista en staging con SCZ-261112-01.

void main() {
  /// Respuesta real del backend (sin `revoked`, con campos extra que se ignoran).
  Map<String, Object?> backendJson() => <String, Object?>{
    'order_number': 'SCZ-261112-01',
    'label_id': '01M73HJXF8MZYBZ4YQW69YF3G7',
    'key_id': 1,
    'sku': 'BAS-QUEEN',
    'line_number': 2,
    'qr_content': '{"v":1}',
    'zpl': '^XA^XZ',
    'emitted_at': 1794341697,
    'product_name': 'Base box Queen',
    'shipment_id': '01a1c719-0000',
    'unit_id': 'U-1',
  };

  test('parsea la etiqueta SIN el campo `revoked` (etiquetas permanentes)', () {
    final label = EmittedLabel.fromJson(backendJson());

    expect(label.orderNumber, 'SCZ-261112-01');
    expect(label.labelId, '01M73HJXF8MZYBZ4YQW69YF3G7');
    expect(label.lineNumber, 2);
    expect(label.emittedAt, 1794341697);
    // Sin el campo, nada queda "anulado".
    expect(label.revoked, isFalse);
  });

  test('sigue parseando si el backend viejo todavía manda `revoked`', () {
    final label = EmittedLabel.fromJson({...backendJson(), 'revoked': true});

    expect(label.revoked, isTrue); // se lee, pero ya no invalida nada
  });
}
