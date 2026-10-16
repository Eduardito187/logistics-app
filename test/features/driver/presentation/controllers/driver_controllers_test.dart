import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';

import '../../support/driver_test_support.dart';

// Providers derivados de la asignación del chofer: el id del vehículo sale de
// la tripulación del día, y las lecturas por vehículo exigen que exista.

void main() {
  test(
    'assignedVehicleIdProvider deriva el id del vehículo asignado',
    () async {
      final container = ProviderContainer(
        overrides: [
          myCrewProvider.overrideWith(
            (ref) async => buildMyCrew(vehicle: buildVehicle(id: 'v-42')),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Mientras carga, el id es null.
      expect(container.read(assignedVehicleIdProvider), isNull);

      await container.read(myCrewProvider.future);
      expect(container.read(assignedVehicleIdProvider), 'v-42');
    },
  );

  test('assignedVehicleIdProvider es null cuando no hay asignación', () async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        myCrewProvider.overrideWith(
          (ref) async => throw const ApiException(status: 404, title: 'x'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(myCrewProvider.future),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(assignedVehicleIdProvider), isNull);
  });

  test(
    'driverRouteProvider lanza ApiException sin vehículo asignado',
    () async {
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          myCrewProvider.overrideWith(
            (ref) async => throw const ApiException(status: 404, title: 'x'),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(driverRouteProvider, (_, _) {});

      await expectLater(
        container.read(driverRouteProvider.future),
        throwsA(
          isA<ApiException>().having(
            (e) => e.title,
            'title',
            'Sin vehículo asignado',
          ),
        ),
      );
    },
  );

  test('vehicleDeliveriesProvider lanza ApiException sin vehículo', () async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        myCrewProvider.overrideWith(
          (ref) async => throw const ApiException(status: 404, title: 'x'),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(vehicleDeliveriesProvider, (_, _) {});

    await expectLater(
      container.read(vehicleDeliveriesProvider.future),
      throwsA(isA<ApiException>()),
    );
  });
}
