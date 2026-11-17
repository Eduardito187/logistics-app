import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/features/store/presentation/widgets/pickup_card.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_status_pill.dart';

import '../../../../support/app_icon_finders.dart';
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
    expect(findAppIcon(AppIcon.chevronRight), findsOneWidget);
  });

  testWidgets('sin documento omite esa línea', (tester) async {
    await _pump(tester, withDoc: false);
    expect(find.textContaining('Doc:'), findsNothing);
  });

  testWidgets('listo para retirar: badge verde con la hora, sin pastilla', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PickupCard(
            shipment: shipment(
              readyForPickupAt: DateTime(2026, 11, 16, 10, 52),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Listo para retirar · Llegó 10:52'), findsOneWidget);
    // Cuando ya se puede entregar, no se muestra la pastilla de estado.
    expect(find.byType(ShipmentStatusPill), findsNothing);
  });

  testWidgets('en camino: muestra la pastilla de estado, sin badge', (
    tester,
  ) async {
    await _pump(tester, withDoc: false);
    expect(find.textContaining('Listo para retirar'), findsNothing);
    expect(find.byType(ShipmentStatusPill), findsOneWidget);
  });
}
