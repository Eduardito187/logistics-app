import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_tracking_autostart.dart';

import '../../support/driver_test_support.dart';

// Selección del envío a rastrear automáticamente: parada en curso o primera
// pendiente; null cuando no hay parada activa (señal para detener el rastreo).

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

  test('null cuando la ruta está completada', () async {
    final route = buildRoute(
      status: DriverRouteStatus.completed,
      stops: [buildStop(status: DriverRouteStopStatus.pending)],
    );
    expect(await _resolve(route), isNull);
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

  test('null cuando no hay ninguna parada pendiente', () async {
    final route = buildRoute(
      status: DriverRouteStatus.inProgress,
      stops: [
        buildStop(status: DriverRouteStopStatus.completed),
        buildStop(id: 's2', sequence: 2, status: DriverRouteStopStatus.failed),
      ],
    );
    expect(await _resolve(route), isNull);
  });
}
