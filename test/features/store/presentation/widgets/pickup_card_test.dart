import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/store/presentation/widgets/pickup_card.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_status_pill.dart';

import '../../store_fixtures.dart';

// Tarjeta de envío para entrega en mostrador: datos del cliente, pedido,
// documento (opcional) y la pastilla de estado.

Future<void> _pump(WidgetTester tester, {required bool withDoc}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PickupCard(
          shipment: shipment(
            customerName: 'Ana Pérez',
            customerDocumentId: withDoc ? '12345678' : null,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('muestra cliente, pedido y documento cuando existe', (
    tester,
  ) async {
    await _pump(tester, withDoc: true);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Pedido DM-260012345'), findsOneWidget);
    expect(find.text('Doc: 12345678'), findsOneWidget);
    expect(find.byType(ShipmentStatusPill), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('sin documento omite esa línea', (tester) async {
    await _pump(tester, withDoc: false);
    expect(find.textContaining('Doc:'), findsNothing);
  });
}
