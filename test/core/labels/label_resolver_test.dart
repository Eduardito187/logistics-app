import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';

// `LabelResolution` parsea la respuesta de `GET /app/labels/{labelId}/resolve`.
// El backend manda `unit`/`piece` anidados (`{index,total}`); se acepta también
// la forma plana por compatibilidad. `revoked`/`order_number` son aditivos.

void main() {
  test('parsea el shape anidado del backend (unit/piece + revoked/order)', () {
    final res = LabelResolution.fromJson(const {
      'label_id': 'LBL-1',
      'resolved': true,
      'revoked': false,
      'order_number': '100000452',
      'unit_id': 'U-1',
      'shipment_id': 'S-1',
      'sku': 'BAS-QUEEN',
      'product_name': 'Base box Queen',
      'line_number': 1,
      'unit': {'index': 2, 'total': 3},
      'piece': {'index': 1, 'total': 4},
    });
    expect(res.resolved, isTrue);
    expect(res.revoked, isFalse);
    expect(res.orderNumber, '100000452');
    expect(res.unitId, 'U-1');
    expect(res.shipmentId, 'S-1');
    expect(res.sku, 'BAS-QUEEN');
    expect(res.unitIndex, 2);
    expect(res.unitTotal, 3);
    expect(res.pieceIndex, 1);
    expect(res.pieceTotal, 4);
    expect(res.accepted, isTrue);
  });

  test('acepta también la forma plana (unit_index/…)', () {
    final res = LabelResolution.fromJson(const {
      'label_id': 'LBL-2',
      'resolved': true,
      'unit_id': 'U-2',
      'unit_index': 1,
      'unit_total': 1,
      'piece_index': 1,
      'piece_total': 1,
    });
    expect(res.unitIndex, 1);
    expect(res.pieceTotal, 1);
    expect(res.accepted, isTrue);
  });

  test('resolved:false → no aceptable (campos nulos)', () {
    final res = LabelResolution.fromJson(const {
      'label_id': 'LBL-X',
      'resolved': false,
      'order_number': '100000999', // puede venir aunque no resuelva
    });
    expect(res.resolved, isFalse);
    expect(res.unitId, isNull);
    expect(res.orderNumber, '100000999');
    expect(res.accepted, isFalse);
  });

  test('revoked:true → no aceptable aunque resuelva', () {
    final res = LabelResolution.fromJson(const {
      'label_id': 'LBL-R',
      'resolved': true,
      'revoked': true,
      'unit_id': 'U-9',
    });
    expect(res.resolved, isTrue);
    expect(res.revoked, isTrue);
    expect(res.accepted, isFalse);
  });

  test('resuelto pero sin unit_id → no aceptable', () {
    final res = LabelResolution.fromJson(const {
      'label_id': 'LBL-Z',
      'resolved': true,
    });
    expect(res.accepted, isFalse);
  });
}
