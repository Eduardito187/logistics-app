import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/load_scan_screen.dart';

import '../support/driver_test_support.dart';

// Carga del camión: lista de envíos asignados al vehículo.

void main() {
  testWidgets('sin envíos muestra el estado vacío', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        ...gateBase(),
        vehicleDeliveriesProvider.overrideWith((ref) async => <Delivery>[]),
      ],
      child: const LoadScanScreen(),
    );

    expect(find.text('Sin envíos'), findsOneWidget);
    expect(
      find.text('No hay envíos asignados a este vehículo.'),
      findsOneWidget,
    );
  });

  testWidgets('lista los envíos con su estado', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        ...gateBase(),
        vehicleDeliveriesProvider.overrideWith(
          (ref) async => [
            buildDelivery(shipmentId: 'ship-1', status: DeliveryStatus.loaded),
            buildDelivery(
              shipmentId: 'ship-2',
              status: DeliveryStatus.delivered,
            ),
          ],
        ),
      ],
      child: const LoadScanScreen(),
    );

    expect(find.text('Envío ship-1'), findsOneWidget);
    expect(find.text('Cargado'), findsOneWidget);
    expect(find.text('Envío ship-2'), findsOneWidget);
    expect(find.text('Entregado'), findsOneWidget);
    expect(find.text('0 escaneo(s)'), findsNWidgets(2));
  });
}
