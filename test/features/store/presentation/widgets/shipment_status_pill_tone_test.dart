import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';
import 'package:logistics_app/features/store/presentation/widgets/shipment_status_pill.dart';

// Complementa shipment_status_pill_test.dart: cubre los estados que faltaban
// (planned, cancelled) y verifica el tono semántico de cada estado, no solo la
// etiqueta.

Future<StatusPill> _pill(WidgetTester tester, ShipmentStatus status) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ShipmentStatusPill(status))),
  );
  return tester.widget<StatusPill>(find.byType(StatusPill));
}

void main() {
  testWidgets('estados faltantes: planned y cancelled', (tester) async {
    expect((await _pill(tester, ShipmentStatus.planned)).label, 'Planificado');
    expect((await _pill(tester, ShipmentStatus.cancelled)).label, 'Cancelado');
  });

  testWidgets('tono semántico de cada estado', (tester) async {
    expect((await _pill(tester, ShipmentStatus.received)).tone, PillTone.info);
    expect((await _pill(tester, ShipmentStatus.planned)).tone, PillTone.info);
    expect(
      (await _pill(tester, ShipmentStatus.inExecution)).tone,
      PillTone.warning,
    );
    expect(
      (await _pill(tester, ShipmentStatus.delivered)).tone,
      PillTone.success,
    );
    expect((await _pill(tester, ShipmentStatus.failed)).tone, PillTone.danger);
    expect(
      (await _pill(tester, ShipmentStatus.cancelled)).tone,
      PillTone.neutral,
    );
    expect(
      (await _pill(tester, ShipmentStatus.$unknown)).tone,
      PillTone.neutral,
    );
  });
}
