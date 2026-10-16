import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/settlement_status.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/settlement_detail.dart';

import '../../carrier_fixtures.dart';

// Detalle de liquidación (widget puro): botones según estado, indicador de
// ocupado y filas de datos.

Future<void> _pump(
  WidgetTester tester, {
  required SettlementStatus status,
  bool busy = false,
  String? disputeReason,
  String? paymentReference,
  String? carrierName,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SettlementDetail(
          settlement: settlement(
            status: status,
            disputeReason: disputeReason,
            paymentReference: paymentReference,
            carrierName: carrierName,
          ),
          busy: busy,
          onApprove: () async {},
          onDispute: () async {},
          onPay: () async {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('enviada: Aprobar + Disputar, sin Pagar', (tester) async {
    await _pump(tester, status: SettlementStatus.submitted);
    expect(find.widgetWithText(FilledButton, 'Aprobar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Disputar'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Marcar como pagada'),
      findsNothing,
    );
  });

  testWidgets('aprobada: solo Pagar', (tester) async {
    await _pump(tester, status: SettlementStatus.approved);
    expect(
      find.widgetWithText(FilledButton, 'Marcar como pagada'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Aprobar'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Disputar'), findsNothing);
  });

  testWidgets('en disputa: solo Aprobar', (tester) async {
    await _pump(tester, status: SettlementStatus.disputed);
    expect(find.widgetWithText(FilledButton, 'Aprobar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Disputar'), findsNothing);
    expect(
      find.widgetWithText(FilledButton, 'Marcar como pagada'),
      findsNothing,
    );
  });

  testWidgets('pagada: sin acciones', (tester) async {
    await _pump(tester, status: SettlementStatus.paid);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('ocupado muestra el indicador y oculta los botones', (
    tester,
  ) async {
    await _pump(tester, status: SettlementStatus.submitted, busy: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Aprobar'), findsNothing);
  });

  testWidgets('muestra filas opcionales cuando están presentes', (
    tester,
  ) async {
    await _pump(
      tester,
      status: SettlementStatus.disputed,
      carrierName: 'Transportes Andinos',
      disputeReason: 'Monto no coincide',
      paymentReference: 'TRX-1',
    );

    expect(find.text('Periodo'), findsOneWidget);
    expect(find.text('Referencia'), findsOneWidget);
    expect(find.text('Transportista'), findsOneWidget);
    expect(find.text('Motivo de disputa'), findsOneWidget);
    expect(find.text('Referencia de pago'), findsOneWidget);
    expect(find.text('Documentos'), findsOneWidget);
  });
}
