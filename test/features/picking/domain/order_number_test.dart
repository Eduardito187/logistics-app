import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/domain/order_number.dart';

// Reglas del número de pedido: corto, alfanumérico, con guiones/puntos/guion
// bajo. El JSON firmado de una etiqueta QR NUNCA es un pedido (bug: el header
// mostraba `Pedido {"v":1,"t":"PKG",…}`).

void main() {
  group('isPlausibleOrderNumber', () {
    test('acepta números de pedido reales', () {
      for (final value in [
        'DIS-123456',
        '100045',
        'DM-260012345',
        'EXT-1',
        'dis-1',
        'A1',
      ]) {
        expect(isPlausibleOrderNumber(value), isTrue, reason: value);
      }
    });

    test('acepta guiones, puntos y guion bajo después del primer carácter', () {
      expect(isPlausibleOrderNumber('DIS.2026_001-A'), isTrue);
      expect(isPlausibleOrderNumber('A.B'), isTrue);
      expect(isPlausibleOrderNumber('A_B'), isTrue);
    });

    test('recorta espacios de los bordes antes de validar', () {
      expect(isPlausibleOrderNumber('  DIS-123456  '), isTrue);
      expect(isPlausibleOrderNumber('\tDIS-1\n'), isTrue);
    });

    test('rechaza vacío o solo espacios', () {
      expect(isPlausibleOrderNumber(''), isFalse);
      expect(isPlausibleOrderNumber('   '), isFalse);
    });

    test('rechaza un solo carácter', () {
      expect(isPlausibleOrderNumber('A'), isFalse);
      expect(isPlausibleOrderNumber('7'), isFalse);
    });

    test('rechaza el JSON firmado de una etiqueta QR', () {
      expect(isPlausibleOrderNumber('{"v":1}'), isFalse);
      expect(
        isPlausibleOrderNumber(
          '{"v":1,"t":"PKG","k":1,"id":"01JB8ZQ4X7K2M9N5P6R7S8T9VW",'
          '"o":"DM-260012345"}',
        ),
        isFalse,
      );
    });

    test('rechaza espacios internos', () {
      expect(isPlausibleOrderNumber('DIS 123456'), isFalse);
      expect(isPlausibleOrderNumber('pedido de prueba'), isFalse);
    });

    test('rechaza si empieza con guion, punto o guion bajo', () {
      expect(isPlausibleOrderNumber('-DIS1'), isFalse);
      expect(isPlausibleOrderNumber('.123'), isFalse);
      expect(isPlausibleOrderNumber('_123'), isFalse);
    });

    test('rechaza URLs, barras y símbolos', () {
      expect(isPlausibleOrderNumber('https://dismac.com.bo/p/1'), isFalse);
      expect(isPlausibleOrderNumber('DIS/1'), isFalse);
      expect(isPlausibleOrderNumber('DIS#1'), isFalse);
      expect(isPlausibleOrderNumber('DIS:1'), isFalse);
      expect(isPlausibleOrderNumber('ÑANDÚ-1'), isFalse);
    });

    test('largo: hasta 40 caracteres sí, 41 no', () {
      final forty = 'A' * 40;
      final fortyOne = 'A' * 41;
      expect(isPlausibleOrderNumber(forty), isTrue);
      expect(isPlausibleOrderNumber(fortyOne), isFalse);
      // Los espacios de los bordes no cuentan para el largo.
      expect(isPlausibleOrderNumber('  $forty  '), isTrue);
    });
  });

  group('orderPreparationPath', () {
    test('arma la ruta de preparación del pedido', () {
      expect(orderPreparationPath('DIS-123456'), '/picking/order/DIS-123456');
      expect(orderPreparationPath('100045'), '/picking/order/100045');
    });

    test('recorta espacios del número', () {
      expect(orderPreparationPath('  DIS-1  '), '/picking/order/DIS-1');
    });

    test('codifica caracteres que romperían la ruta', () {
      expect(orderPreparationPath('A B'), '/picking/order/A%20B');
      expect(orderPreparationPath('a/b'), '/picking/order/a%2Fb');
      expect(orderPreparationPath('x?y#z'), '/picking/order/x%3Fy%23z');
      expect(
        orderPreparationPath('{"v":1}'),
        '/picking/order/%7B%22v%22%3A1%7D',
      );
    });

    test('guiones, puntos y guion bajo quedan tal cual', () {
      expect(
        orderPreparationPath('DIS.2026_001-A'),
        '/picking/order/DIS.2026_001-A',
      );
    });

    test('el resultado decodifica de vuelta al número original', () {
      const original = 'A B/C';
      final path = orderPreparationPath(original);
      final segment = path.substring('/picking/order/'.length);
      expect(Uri.decodeComponent(segment), original);
    });
  });
}
