import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/feature_tasks.dart';
import 'package:logistics_app/core/navigation/role_task.dart';

// featureTasksProvider agrega las tarjetas de todos los features de campo. El
// contrato clave: solo roles de terreno (chofer, preparador, tienda,
// transportista, supervisor) y NINGUNA vista admin/oficina.
void main() {
  late ProviderContainer container;
  late List<RoleTask> tasks;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    tasks = container.read(featureTasksProvider);
  });

  test('agrega tareas de todos los features (lista no vacía)', () {
    expect(tasks, isNotEmpty);
  });

  test('cada tarea declara al menos un rol de campo', () {
    const fieldRoles = {
      UserRole.driver,
      UserRole.picker,
      UserRole.store,
      UserRole.carrier,
      UserRole.supervisor,
    };
    for (final task in tasks) {
      expect(task.roles, isNotEmpty, reason: 'tarea ${task.id} sin roles');
      expect(
        task.roles.every(fieldRoles.contains),
        isTrue,
        reason: 'tarea ${task.id} usa un rol fuera de los de campo',
      );
    }
  });

  test('ninguna ruta apunta al admin/oficina (/admin)', () {
    for (final task in tasks) {
      expect(
        task.route.startsWith('/admin'),
        isFalse,
        reason: 'tarea ${task.id} apunta al admin',
      );
    }
  });

  test('están las tarjetas de campo esperadas por feature', () {
    final ids = tasks.map((t) => t.id).toSet();
    // Chofer, preparador, tienda, transportista y supervisor representados.
    expect(ids, containsAll(<String>['driver-route', 'driver-load']));
    expect(ids, containsAll(<String>['picking-orders', 'picking-prepare']));
    expect(ids, containsAll(<String>['store-reception', 'store-pickup']));
    expect(ids, containsAll(<String>['carrier-pickup', 'carrier-deliver']));
    expect(ids, containsAll(<String>['sup-dashboard', 'sup-alerts']));
    // Transversales compartidas.
    expect(ids, containsAll(<String>['notifications', 'settings']));
  });

  test('las ids de las tarjetas son únicas', () {
    final ids = tasks.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
