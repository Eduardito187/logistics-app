import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/store/presentation/short_unit_id.dart';

// `shortUnitId` abrevia los UUID largos para listas: deja los últimos 6 con un
// prefijo "…", pero devuelve el id tal cual si mide 8 o menos.

void main() {
  group('shortUnitId', () {
    test('ids de 8 o menos se devuelven sin cambios', () {
      expect(shortUnitId('abc'), 'abc');
      expect(shortUnitId('12345678'), '12345678');
    });

    test('ids largos se abrevian a los últimos 6 con prefijo …', () {
      expect(shortUnitId('123456789'), '…456789');
      expect(shortUnitId('01JB8ZQ4X7K2M9N5P6R7S8T9VW'), '…S8T9VW');
    });

    test('un id vacío se devuelve igual (caso borde)', () {
      expect(shortUnitId(''), '');
    });
  });
}
