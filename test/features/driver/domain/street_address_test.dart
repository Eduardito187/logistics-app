import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/domain/entities/street_address.dart';

void main() {
  group('streetAddress', () {
    test('quita la ciudad y deja calle y barrio', () {
      expect(
        streetAddress(
          'Av. Roca y Coronado 3er anillo externo, Barrio Las Palmas, '
          'Santa Cruz de la Sierra',
        ),
        'Av. Roca y Coronado 3er anillo externo, Barrio Las Palmas',
      );
    });

    test('quita municipio, departamento y país sin importar acentos', () {
      expect(
        streetAddress('Calle 5 #120, Municipio de Warnes, Santa Cruz, Bolivia'),
        'Calle 5 #120',
      );
      expect(
        streetAddress(
          'Av. Blanco Galindo km 5, Quillacollo, Depto. Cochabamba',
        ),
        'Av. Blanco Galindo km 5',
      );
      expect(streetAddress('Calle Sucre 45, POTOSÍ'), 'Calle Sucre 45');
    });

    test('no toca calles con nombre de ciudad dentro del tramo', () {
      expect(
        streetAddress('Calle La Paz 300, Equipetrol'),
        'Calle La Paz 300, Equipetrol',
      );
    });

    test('si todo es ciudad devuelve el texto original', () {
      expect(
        streetAddress('Santa Cruz de la Sierra'),
        'Santa Cruz de la Sierra',
      );
    });
  });
}
