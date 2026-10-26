import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/features/driver/presentation/driver_routes.dart';

// Contrato de integración del chofer: tarjetas de inicio (RoleTask) y rutas
// go_router. El coordinador cablea estos nombres, así que se fijan acá.

void main() {
  test('las tareas del chofer son todas del rol driver', () {
    expect(driverTasks, isNotEmpty);
    for (final task in driverTasks) {
      expect(
        task.roles,
        contains(UserRole.driver),
        reason: 'la tarjeta ${task.id} debe ser del rol chofer',
      );
    }
  });

  test('ids y rutas esperados', () {
    final routesById = {for (final t in driverTasks) t.id: t.route};
    expect(routesById, {
      'driver-active-delivery': '/driver/delivery',
      'driver-route': '/driver/route',
      'driver-my-day': '/driver/my-day',
      'driver-checklist': '/driver/checklist',
      'driver-load': '/driver/load',
      'driver-gps': '/driver/gps',
      'driver-incident': '/driver/incident',
      'driver-summary': '/driver/summary',
      'driver-fuel': '/driver/fuel',
      'driver-odometer': '/driver/odometer',
      'driver-maintenance': '/driver/maintenance',
    });
  });

  test('"Entrega en curso" es la acción principal (accent)', () {
    final active = driverTasks.firstWhere(
      (t) => t.id == 'driver-active-delivery',
    );
    expect(active.accent, isTrue);
    expect(driverTasks.first.id, 'driver-active-delivery');
    final route = driverTasks.firstWhere((t) => t.id == 'driver-route');
    expect(route.accent, isFalse);
  });

  test('cada tarjeta tiene su GoRoute registrada', () {
    final paths = driverRoutes.whereType<GoRoute>().map((r) => r.path).toSet();
    for (final task in driverTasks) {
      expect(
        paths,
        contains(task.route),
        reason: 'falta la GoRoute de ${task.route}',
      );
    }
    expect(paths, hasLength(driverTasks.length));
  });
}
