import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/widgets/delivery_state_card.dart';

import '../support/driver_test_support.dart';

// Estado detallado de la entrega del envío (status real + escaneos + falla).

void main() {
  testWidgets('con dato muestra estado, escaneos, confirmación y falla', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        deliveryStateProvider('ship-1').overrideWith(
          (ref) async => buildDelivery(
            status: DeliveryStatus.failed,
            podConfirmation: 'QR-123',
            failureReason: FailureReason.customerAbsent,
          ),
        ),
      ],
      child: const Scaffold(body: DeliveryStateCard(shipmentId: 'ship-1')),
    );

    expect(find.text('Estado de la entrega'), findsOneWidget);
    expect(find.text('Fallida'), findsOneWidget);
    expect(find.text('0 escaneo(s) registrados'), findsOneWidget);
    expect(find.text('Confirmación: QR-123'), findsOneWidget);
    expect(find.text('Motivo de falla: Cliente ausente'), findsOneWidget);
  });

  testWidgets('entregada muestra "Entregada"', (tester) async {
    await pumpScoped(
      tester,
      overrides: [
        deliveryStateProvider('ship-2').overrideWith(
          (ref) async => buildDelivery(
            shipmentId: 'ship-2',
            status: DeliveryStatus.delivered,
          ),
        ),
      ],
      child: const Scaffold(body: DeliveryStateCard(shipmentId: 'ship-2')),
    );
    expect(find.text('Entregada'), findsOneWidget);
  });

  testWidgets('en error muestra el estado de carga con reintento', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        deliveryStateProvider('ship-err').overrideWith(
          (ref) async => throw const ApiException(status: 500, title: 'x'),
        ),
      ],
      child: const Scaffold(body: DeliveryStateCard(shipmentId: 'ship-err')),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
