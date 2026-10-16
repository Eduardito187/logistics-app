import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';
import 'package:logistics_app/features/picking/presentation/widgets/shipment_status_pill.dart';

// Pastilla de estado del pedido del preparador. Mapea cada ShipmentStatus a un
// texto en español y a un tono (color semántico) del StatusPill.

Future<void> _pump(WidgetTester tester, ShipmentStatus status) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ShipmentStatusPill(status))),
  );
}

PillTone _toneOf(WidgetTester tester) =>
    tester.widget<StatusPill>(find.byType(StatusPill)).tone;

void main() {
  testWidgets('received → "Por preparar" tono info', (tester) async {
    await _pump(tester, ShipmentStatus.received);
    expect(find.text('Por preparar'), findsOneWidget);
    expect(_toneOf(tester), PillTone.info);
  });

  testWidgets('planned → "Planificado" tono warning', (tester) async {
    await _pump(tester, ShipmentStatus.planned);
    expect(find.text('Planificado'), findsOneWidget);
    expect(_toneOf(tester), PillTone.warning);
  });

  testWidgets('inExecution → "En ejecución" tono warning', (tester) async {
    await _pump(tester, ShipmentStatus.inExecution);
    expect(find.text('En ejecución'), findsOneWidget);
    expect(_toneOf(tester), PillTone.warning);
  });

  testWidgets('delivered → "Entregado" tono success', (tester) async {
    await _pump(tester, ShipmentStatus.delivered);
    expect(find.text('Entregado'), findsOneWidget);
    expect(_toneOf(tester), PillTone.success);
  });

  testWidgets('failed → "Fallido" tono danger', (tester) async {
    await _pump(tester, ShipmentStatus.failed);
    expect(find.text('Fallido'), findsOneWidget);
    expect(_toneOf(tester), PillTone.danger);
  });

  testWidgets('cancelled → "Cancelado" tono neutral', (tester) async {
    await _pump(tester, ShipmentStatus.cancelled);
    expect(find.text('Cancelado'), findsOneWidget);
    expect(_toneOf(tester), PillTone.neutral);
  });

  testWidgets(r'$unknown → "Desconocido" tono neutral', (tester) async {
    await _pump(tester, ShipmentStatus.$unknown);
    expect(find.text('Desconocido'), findsOneWidget);
    expect(_toneOf(tester), PillTone.neutral);
  });
}
