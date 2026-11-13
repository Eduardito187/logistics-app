import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_tracking_autostart.dart';

import '../../support/driver_test_support.dart';

// Selección del envío a rastrear automáticamente: parada en curso o primera
// pendiente; si ya no quedan pendientes se sigue rastreando el ÚLTIMO envío
// (regreso al CD). null solo mientras no hay ruta o la ruta no tiene paradas.

Future<String?> _resolve(DriverRoute route) async {
  final container = ProviderContainer(
    overrides: [driverRouteProvider.overrideWith((ref) async => route)],
  );
  addTearDown(container.dispose);
  container.listen(driverRouteProvider, (_, _) {});
  await container.read(driverRouteProvider.future);
  return container.read(activeTrackingShipmentIdProvider);
}

void main() {
  test('null mientras la ruta está cargando', () async {
    final container = ProviderContainer(
      overrides: [
        driverRouteProvider.overrideWith(
          (ref) => Completer<DriverRoute>().future, // nunca resuelve
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(driverRouteProvider, (_, _) {});

    expect(container.read(activeTrackingShipmentIdProvider), isNull);
  });

  test('la ruta "completada" por el backend con una parada pendiente la rastrea', () async {
    // El backend dice completada pero una parada sigue pendiente (el bug del
    // dueño): el seguimiento NO debe apagarse, debe rastrear esa parada.
    final route = buildRoute(
      status: DriverRouteStatus.completed,
      stops: [buildStop(shipmentId: 'ship-1', status: DriverRouteStopStatus.pending)],
    );
    expect(await _resolve(route), 'ship-1');
  });

  test('usa el envío de la parada en curso si está pendiente', () async {
    final current = buildStop(
      id: 'cur',
      shipmentId: 'ship-current',
      status: DriverRouteStopStatus.pending,
    );
    final route = buildRoute(
      status: DriverRouteStatus.inProgress,
      currentStop: current,
      stops: [
        buildStop(
          id: 's2',
          shipmentId: 'ship-2',
          sequence: 2,
          status: DriverRouteStopStatus.pending,
        ),
      ],
    );
    expect(await _resolve(route), 'ship-current');
  });

  test(
    'cae a la primera parada pendiente si la actual no es pendiente',
    () async {
      final current = buildStop(
        id: 'cur',
        shipmentId: 'ship-current',
        status: DriverRouteStopStatus.completed,
      );
      final route = buildRoute(
        status: DriverRouteStatus.inProgress,
        currentStop: current,
        stops: [
          buildStop(
            id: 's1',
            shipmentId: 'ship-done',
            sequence: 1,
            status: DriverRouteStopStatus.completed,
          ),
          buildStop(
            id: 's2',
            shipmentId: 'ship-pending',
            sequence: 2,
            status: DriverRouteStopStatus.pending,
          ),
        ],
      );
      expect(await _resolve(route), 'ship-pending');
    },
  );

  test('sin pendientes sigue rastreando el ÚLTIMO envío (regreso al CD)', () async {
    // Todas las paradas atendidas: el camión vuelve al centro de distribución y
    // debe seguir rastreándose (hasta cerrar sesión). Se asocia al último envío.
    final route = buildRoute(
      status: DriverRouteStatus.inProgress,
      stops: [
        buildStop(
          shipmentId: 'ship-1',
          status: DriverRouteStopStatus.completed,
        ),
        buildStop(
          id: 's2',
          shipmentId: 'ship-2',
          sequence: 2,
          status: DriverRouteStopStatus.failed,
        ),
      ],
    );
    expect(await _resolve(route), 'ship-2');
  });

  test('null cuando la ruta no tiene paradas', () async {
    expect(await _resolve(buildEmptyRoute()), isNull);
  });
}
