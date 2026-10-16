import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_tracking_autostart.dart';

import '../../support/driver_test_support.dart';

// El efecto que arranca/detiene el rastreo automáticamente (sin botón) al montar
// el gate del chofer.

Future<FakeTruckTracking> _mount(WidgetTester tester, DriverRoute route) async {
  final container = ProviderContainer(
    overrides: [
      truckTrackingProvider.overrideWith(FakeTruckTracking.new),
      driverRouteProvider.overrideWith((ref) async => route),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: DriverTrackingAutostart(child: SizedBox()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container.read(truckTrackingProvider.notifier) as FakeTruckTracking;
}

void main() {
  testWidgets('con parada pendiente arranca el rastreo con su shipmentId', (
    tester,
  ) async {
    final tracking = await _mount(
      tester,
      buildRoute(
        status: DriverRouteStatus.inProgress,
        currentStop: buildStop(
          shipmentId: 'ship-live',
          status: DriverRouteStopStatus.pending,
        ),
        stops: [
          buildStop(
            shipmentId: 'ship-live',
            status: DriverRouteStopStatus.pending,
          ),
        ],
      ),
    );

    expect(tracking.startCount, greaterThanOrEqualTo(1));
    expect(tracking.state.active, isTrue);
    expect(tracking.state.shipmentId, 'ship-live');
  });

  testWidgets('ruta completada detiene el rastreo', (tester) async {
    final tracking = await _mount(tester, buildEmptyRoute());

    expect(tracking.stopCount, greaterThanOrEqualTo(1));
    expect(tracking.state.active, isFalse);
  });
}
