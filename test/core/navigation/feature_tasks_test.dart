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

  test('cada tarea declara al menos un rol de la app', () {
    const fieldRoles = {
      // El administrador entra a la app desde nov 2026 (decisión del dueño).
      UserRole.admin,
      UserRole.driver,
      UserRole.picker,
      UserRole.store,
      UserRole.carrier,
      // Tripulante (ayudante del camión): login de solo lectura (nov 2026).
      UserRole.crewMember,
      UserRole.supervisor,
      // Planificador: arma y publica los planes (nov 2026).
      UserRole.planner,
    };
    for (final task in tasks) {
      expect(task.roles, isNotEmpty, reason: 'tarea ${task.id} sin roles');
      expect(
        task.roles.every(fieldRoles.contains),
        isTrue,
        reason: 'tarea ${task.id} usa un rol desconocido',
      );
    }
  });

  test('las rutas /admin son del administrador (y tres del planificador)', () {
    // Envíos, reprogramar y calendario también son trabajo del planificador.
    const shared = {'admin-shipments', 'admin-reschedule', 'admin-calendar'};
    for (final task in tasks.where((t) => t.route.startsWith('/admin'))) {
      expect(
        task.roles,
        shared.contains(task.id)
            ? {UserRole.planner, UserRole.admin}
            : {UserRole.admin},
        reason: 'tarea ${task.id} de administración visible para otro rol',
      );
    }
  });

  test('están las tarjetas de campo esperadas por feature', () {
    final ids = tasks.map((t) => t.id).toSet();
    // Chofer, preparador, tienda, transportista y supervisor representados.
    expect(ids, containsAll(<String>['driver-route', 'driver-load']));
    expect(ids, containsAll(<String>['picking-orders', 'picking-prepare']));
    // La tienda solo entrega al cliente final: sin recepción de mercadería.
    expect(ids, contains('store-pickup'));
    expect(ids, isNot(contains('store-reception')));
    expect(ids, containsAll(<String>['carrier-pickup', 'carrier-deliver']));
    expect(ids, containsAll(<String>['sup-dashboard', 'sup-alerts']));
    // Transversales compartidas.
    expect(ids, contains('settings'));
    // Notificaciones no es tarjeta: se abre con la campana del header.
    expect(ids, isNot(contains('notifications')));
  });

  test('las ids de las tarjetas son únicas', () {
    final ids = tasks.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
