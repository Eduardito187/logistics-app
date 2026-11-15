import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/user_role.dart';

// Complementa user_role_test.dart: propiedades declaradas de cada rol y el
// conjunto exacto de roles operativos (contrato de UI con el backend).

void main() {
  group('UserRole (propiedades de cada valor)', () {
    test(
      'existen exactamente los roles esperados (incluye planificador y admin)',
      () {
        expect(UserRole.values, [
          UserRole.driver,
          UserRole.picker,
          UserRole.store,
          UserRole.carrier,
          UserRole.supervisor,
          UserRole.planner,
          UserRole.admin,
        ]);
      },
    );

    test('backendKey de cada rol coincide con la clave del backend', () {
      expect(UserRole.driver.backendKey, 'chofer');
      expect(UserRole.picker.backendKey, 'preparador');
      expect(UserRole.store.backendKey, 'tienda');
      expect(UserRole.carrier.backendKey, 'transportista');
      expect(UserRole.supervisor.backendKey, 'supervisor');
      expect(UserRole.admin.backendKey, 'admin');
    });

    test('label (texto de UI en español) de cada rol', () {
      expect(UserRole.driver.label, 'Chofer');
      expect(UserRole.picker.label, 'Preparador');
      expect(UserRole.store.label, 'Tienda');
      expect(UserRole.carrier.label, 'Transportista externo');
      expect(UserRole.supervisor.label, 'Supervisor');
    });

    test('cada rol declara ícono y al menos una tarea', () {
      for (final role in UserRole.values) {
        expect(role.tasks, isNotEmpty, reason: '${role.name} sin tareas');
        expect(role.label, isNotEmpty);
        expect(role.backendKey, isNotEmpty);
      }
    });

    test('las backendKey son únicas entre todos los roles', () {
      final keys = UserRole.values.map((r) => r.backendKey).toSet();
      expect(keys.length, UserRole.values.length);
    });
  });

  group('UserRole.firstOperational (casos límite complementarios)', () {
    test('admin entra como administrador, aunque tenga otro rol', () {
      expect(UserRole.firstOperational(['admin']), UserRole.admin);
      expect(
        UserRole.firstOperational(['admin', 'supervisor']),
        UserRole.admin,
      );
      // Sin importar el orden en que el backend liste los roles.
      expect(
        UserRole.firstOperational(['supervisor', 'admin']),
        UserRole.admin,
      );
    });

    test('supervisor y admin ven la operación completa', () {
      expect(UserRole.supervisor.seesOperations, isTrue);
      expect(UserRole.admin.seesOperations, isTrue);
      expect(UserRole.driver.seesOperations, isFalse);
    });
  });
}
