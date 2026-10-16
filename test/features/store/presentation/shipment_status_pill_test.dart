import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_status_pill.dart';

// La pastilla de estado de envío traduce el enum a texto en español. Widget
// simple sin red: se monta y se verifica la etiqueta mostrada.

Future<void> _pump(WidgetTester tester, ShipmentStatus status) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ShipmentStatusPill(status))),
  );
}

void main() {
  testWidgets('muestra el texto en español de cada estado', (tester) async {
    await _pump(tester, ShipmentStatus.received);
    expect(find.text('Recibido'), findsOneWidget);

    await _pump(tester, ShipmentStatus.inExecution);
    expect(find.text('En ejecución'), findsOneWidget);

    await _pump(tester, ShipmentStatus.delivered);
    expect(find.text('Entregado'), findsOneWidget);

    await _pump(tester, ShipmentStatus.failed);
    expect(find.text('Fallido'), findsOneWidget);

    await _pump(tester, ShipmentStatus.$unknown);
    expect(find.text('Desconocido'), findsOneWidget);
  });
}
