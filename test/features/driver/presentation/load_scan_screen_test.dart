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

  testWidgets('lista SOLO lo que falta cargar: lo entregado no aparece', (
    tester,
  ) async {
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

    expect(find.text('Envío 1'), findsOneWidget);
    expect(find.text('Cargado'), findsOneWidget);
    // El entregado ya no se ofrece para cargar.
    expect(find.text('Envío 2'), findsNothing);
    expect(find.text('Entregado'), findsNothing);
    expect(find.text('0 escaneo(s)'), findsOneWidget);
  });

  testWidgets('muestra cliente y nº de pedido de la hoja de ruta', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        ...gateBase(
          route: buildRoute(
            stops: [
              buildStop(
                id: 'a',
                shipmentId: 'ship-1',
                customerName: 'María Pérez',
                orderReference: 'SCZ-1001',
              ),
              // Parada ya entregada: su envío no se ofrece aunque la entrega
              // todavía figure "cargada" en la lista del vehículo.
              buildStop(
                id: 'b',
                shipmentId: 'ship-2',
                sequence: 2,
                customerName: 'Juan Rojas',
                status: DriverRouteStopStatus.completed,
              ),
            ],
          ),
        ),
        vehicleDeliveriesProvider.overrideWith(
          (ref) async => [
            buildDelivery(shipmentId: 'ship-1'),
            buildDelivery(id: 'del-2', shipmentId: 'ship-2'),
          ],
        ),
      ],
      child: const LoadScanScreen(),
    );

    expect(find.text('María Pérez'), findsOneWidget);
    expect(find.text('Pedido SCZ-1001'), findsOneWidget);
    expect(find.text('Juan Rojas'), findsNothing);
    expect(find.text('Envío 1'), findsNothing);
  });

  testWidgets('todo entregado: no queda nada por cargar', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        ...gateBase(),
        vehicleDeliveriesProvider.overrideWith(
          (ref) async => [buildDelivery(status: DeliveryStatus.delivered)],
        ),
      ],
      child: const LoadScanScreen(),
    );

    expect(find.text('Nada por cargar'), findsOneWidget);
  });
}
