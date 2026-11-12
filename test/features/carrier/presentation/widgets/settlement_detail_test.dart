import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/settlement_status.dart';
import 'package:logistics_app/core/widgets/brand_loader.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/settlement_actions_permissions.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/settlement_detail.dart';

import '../../carrier_fixtures.dart';
import '../../../../support/button_finders.dart';

// Detalle de liquidación (widget puro): botones según estado Y permiso,
// indicador de ocupado y filas de datos.

/// Permisos de oficina (puede todo): el estado es lo único que decide.
const _allPermissions = SettlementActionsPermissions(
  canApprove: true,
  canDispute: true,
  canPay: true,
);

/// Permisos del transportista: solo puede disputar.
const _disputeOnly = SettlementActionsPermissions(
  canApprove: false,
  canDispute: true,
  canPay: false,
);

Future<void> _pump(
  WidgetTester tester, {
  required SettlementStatus status,
  bool busy = false,
  String? disputeReason,
  String? paymentReference,
  String? carrierName,
  SettlementActionsPermissions permissions = _allPermissions,
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
          permissions: permissions,
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
    expect(findButtonWithText<FilledButton>('Aprobar'), findsOneWidget);
    expect(findButtonWithText<OutlinedButton>('Disputar'), findsOneWidget);
    expect(
      findButtonWithText<FilledButton>('Marcar como pagada'),
      findsNothing,
    );
  });

  testWidgets('aprobada: solo Pagar', (tester) async {
    await _pump(tester, status: SettlementStatus.approved);
    expect(
      findButtonWithText<FilledButton>('Marcar como pagada'),
      findsOneWidget,
    );
    expect(findButtonWithText<FilledButton>('Aprobar'), findsNothing);
    expect(findButtonWithText<OutlinedButton>('Disputar'), findsNothing);
  });

  testWidgets('en disputa: solo Aprobar', (tester) async {
    await _pump(tester, status: SettlementStatus.disputed);
    expect(findButtonWithText<FilledButton>('Aprobar'), findsOneWidget);
    expect(findButtonWithText<OutlinedButton>('Disputar'), findsNothing);
    expect(
      findButtonWithText<FilledButton>('Marcar como pagada'),
      findsNothing,
    );
  });

  testWidgets('pagada: sin acciones', (tester) async {
    await _pump(tester, status: SettlementStatus.paid);
    expect(findButton<FilledButton>(), findsNothing);
    expect(findButton<OutlinedButton>(), findsNothing);
  });

  testWidgets('ocupado muestra el indicador y oculta los botones', (
    tester,
  ) async {
    await _pump(tester, status: SettlementStatus.submitted, busy: true);
    expect(find.byType(BrandLoader), findsOneWidget);
    expect(findButtonWithText<FilledButton>('Aprobar'), findsNothing);
  });

  testWidgets('sin permiso de aprobar: el botón Aprobar NO está', (
    tester,
  ) async {
    await _pump(
      tester,
      status: SettlementStatus.submitted,
      permissions: _disputeOnly,
    );
    expect(findButtonWithText<FilledButton>('Aprobar'), findsNothing);
    // Su acción propia sigue disponible.
    expect(findButtonWithText<OutlinedButton>('Disputar'), findsOneWidget);
  });

  testWidgets('sin permiso de pagar: el botón Marcar como pagada NO está', (
    tester,
  ) async {
    await _pump(
      tester,
      status: SettlementStatus.approved,
      permissions: _disputeOnly,
    );
    expect(
      findButtonWithText<FilledButton>('Marcar como pagada'),
      findsNothing,
    );
  });

  testWidgets('sin permiso de disputar: el botón Disputar NO está', (
    tester,
  ) async {
    await _pump(
      tester,
      status: SettlementStatus.submitted,
      permissions: const SettlementActionsPermissions(
        canApprove: true,
        canDispute: false,
        canPay: true,
      ),
    );
    expect(findButtonWithText<OutlinedButton>('Disputar'), findsNothing);
    expect(findButtonWithText<FilledButton>('Aprobar'), findsOneWidget);
  });

  testWidgets('sin ningún permiso: ninguna acción financiera', (tester) async {
    await _pump(
      tester,
      status: SettlementStatus.submitted,
      permissions: SettlementActionsPermissions.none,
    );
    expect(findButton<FilledButton>(), findsNothing);
    expect(findButton<OutlinedButton>(), findsNothing);
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
