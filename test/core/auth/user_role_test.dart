import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/user_role.dart';

// Mapeo de claves del backend a roles de la app. Es el contrato con
// `App\Enums\Role` del backend: si cambia una clave, estos tests lo avisan.

void main() {
  group('UserRole.fromBackendKey', () {
    test('mapea cada clave operativa a su rol', () {
      expect(UserRole.fromBackendKey('chofer'), UserRole.driver);
      expect(UserRole.fromBackendKey('preparador'), UserRole.picker);
      expect(UserRole.fromBackendKey('tienda'), UserRole.store);
      expect(UserRole.fromBackendKey('transportista'), UserRole.carrier);
      expect(UserRole.fromBackendKey('supervisor'), UserRole.supervisor);
    });

    test('devuelve null para una clave desconocida o no operativa', () {
      expect(UserRole.fromBackendKey('admin'), isNull);
      expect(UserRole.fromBackendKey('contador'), isNull);
      expect(UserRole.fromBackendKey(''), isNull);
      expect(
        UserRole.fromBackendKey('Chofer'),
        isNull,
      ); // sensible a mayúsculas
    });

    test('cada backendKey declarado redondea a su propio rol', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromBackendKey(role.backendKey), role);
      }
    });
  });

  group('UserRole.firstOperational', () {
    test('elige el primer rol operativo de la lista', () {
      expect(
        UserRole.firstOperational(['contador', 'chofer', 'supervisor']),
        UserRole.driver,
      );
    });

    test('respeta el orden: devuelve el primero que mapea', () {
      expect(
        UserRole.firstOperational(['supervisor', 'chofer']),
        UserRole.supervisor,
      );
    });

    test('ignora claves no operativas hasta encontrar una válida', () {
      expect(
        UserRole.firstOperational(['contador', 'otro', 'tienda']),
        UserRole.store,
      );
    });

    test('devuelve null si ninguna clave es operativa', () {
      expect(UserRole.firstOperational(['contador', 'root']), isNull);
    });

    test('devuelve null para una lista vacía', () {
      expect(UserRole.firstOperational(const <String>[]), isNull);
    });
  });
}
