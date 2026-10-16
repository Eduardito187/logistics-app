import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/widgets/stop_card.dart';

import '../support/driver_test_support.dart';

// Tarjeta de parada: datos, estado y navegación al detalle al tocarla.

void main() {
  testWidgets('muestra cliente, dirección, ETA y estado', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: StopCard(
          stop: buildStop(
            sequence: 3,
            customerName: 'Ferretería Sur',
            address: 'Av. Siempre Viva 123',
            etaAt: DateTime(2026, 10, 15, 14, 5),
            status: DriverRouteStopStatus.pending,
          ),
        ),
      ),
    );

    expect(find.text('Ferretería Sur'), findsOneWidget);
    expect(find.text('Av. Siempre Viva 123'), findsOneWidget);
    expect(find.text('ETA 14:05'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // número de secuencia
  });

  testWidgets('sin cliente usa la referencia del pedido', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: StopCard(
          stop: buildStop(customerName: null, orderReference: 'PED-77'),
        ),
      ),
    );
    expect(find.text('PED-77'), findsOneWidget);
  });

  testWidgets('sin cliente ni referencia usa "Parada N"', (tester) async {
    await pumpScoped(
      tester,
      child: Scaffold(
        body: StopCard(stop: buildStop(sequence: 9, customerName: null)),
      ),
    );
    expect(find.text('Parada 9'), findsOneWidget);
  });

  testWidgets('al tocarla abre el detalle de la parada', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        deliveryStateProvider('ship-1')
            .overrideWith((ref) async => buildDelivery()),
      ],
      child: Scaffold(
        body: StopCard(stop: buildStop(sequence: 1, shipmentId: 'ship-1')),
      ),
    );

    await tester.tap(find.byType(StopCard));
    await tester.pumpAndSettle();

    // StopDetailScreen abre con el título "Parada 1".
    expect(find.text('Parada 1'), findsOneWidget);
  });
}
