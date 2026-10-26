import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/api/models/settlement_status.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_settlement_detail_screen.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';

import '../carrier_fixtures.dart';
import '../carrier_test_harness.dart';
import '../../../support/button_finders.dart';

// Detalle de liquidación: visibilidad de acciones según estado y los comandos
// async (aprobar/disputar/pagar → 202 "Aceptado. Se está procesando.") en sus
// caminos ok y error.

const _id = 's1';

Future<FakeCarrierRepository> _pump(
  WidgetTester tester, {
  required Settlement data,
  FakeCarrierRepository? repo,
  Future<Settlement> Function()? loader,
}) async {
  final fakeRepo = repo ?? FakeCarrierRepository();
  final overrides = <Override>[
    carrierRepositoryProvider.overrideWithValue(fakeRepo),
    carrierSettlementProvider(
      _id,
    ).overrideWith((ref) => loader != null ? loader() : Future.value(data)),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        home: CarrierSettlementDetailScreen(settlementId: _id),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakeRepo;
}

void main() {
  testWidgets('estado enviada: ofrece Aprobar y Disputar, no Pagar', (
    tester,
  ) async {
    await _pump(tester, data: settlement(status: SettlementStatus.submitted));

    expect(find.text('LPZ → SCZ'), findsOneWidget);
    expect(find.text('Enviada'), findsOneWidget);
    expect(findButtonWithText<FilledButton>('Aprobar'), findsOneWidget);
    expect(findButtonWithText<OutlinedButton>('Disputar'), findsOneWidget);
    expect(
      findButtonWithText<FilledButton>('Marcar como pagada'),
      findsNothing,
    );
  });

  testWidgets('estado aprobada: ofrece solo Marcar como pagada', (
    tester,
  ) async {
    await _pump(tester, data: settlement(status: SettlementStatus.approved));

    expect(
      findButtonWithText<FilledButton>('Marcar como pagada'),
      findsOneWidget,
    );
    expect(findButtonWithText<FilledButton>('Aprobar'), findsNothing);
    expect(findButtonWithText<OutlinedButton>('Disputar'), findsNothing);
  });

  testWidgets('estado en disputa: ofrece Aprobar y muestra el motivo', (
    tester,
  ) async {
    await _pump(
      tester,
      data: settlement(
        status: SettlementStatus.disputed,
        disputeReason: 'Monto no coincide',
      ),
    );

    expect(findButtonWithText<FilledButton>('Aprobar'), findsOneWidget);
    expect(findButtonWithText<OutlinedButton>('Disputar'), findsNothing);
    expect(find.text('Monto no coincide'), findsOneWidget);
  });

  testWidgets('aprobar ok: llama al repo y avisa 202 "en proceso"', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      data: settlement(status: SettlementStatus.submitted),
    );

    await tester.tap(findButtonWithText<FilledButton>('Aprobar'));
    await tester.pumpAndSettle();

    expect(repo.approveCalls, 1);
    expect(find.text('Aceptado. Se está procesando.'), findsOneWidget);
  });

  testWidgets('aprobar con error de API muestra el mensaje de error', (
    tester,
  ) async {
    final repo = FakeCarrierRepository(
      onApprove: (_) async => throw const ApiException(
        status: 409,
        title: 'Conflicto',
        detail: 'Ya no se puede aprobar.',
      ),
    );
    await _pump(
      tester,
      data: settlement(status: SettlementStatus.submitted),
      repo: repo,
    );

    await tester.tap(findButtonWithText<FilledButton>('Aprobar'));
    await tester.pumpAndSettle();

    expect(find.text('Ya no se puede aprobar.'), findsOneWidget);
    expect(find.text('Aceptado. Se está procesando.'), findsNothing);
  });

  testWidgets(
    'disputar: escribe motivo, confirma y llama al repo con el motivo',
    (tester) async {
      final repo = await _pump(
        tester,
        data: settlement(status: SettlementStatus.submitted),
      );

      await tester.tap(findButtonWithText<OutlinedButton>('Disputar'));
      await tester.pumpAndSettle();
      expect(find.text('Disputar liquidación'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Faltan bultos');
      await tester.tap(findButtonWithText<FilledButton>('Disputar'));
      await tester.pumpAndSettle();

      expect(repo.disputeCalls, 1);
      expect(repo.lastDisputeReason, 'Faltan bultos');
      expect(find.text('Aceptado. Se está procesando.'), findsOneWidget);
    },
  );

  testWidgets('disputar con motivo vacío no llama al repo', (tester) async {
    final repo = await _pump(
      tester,
      data: settlement(status: SettlementStatus.submitted),
    );

    await tester.tap(findButtonWithText<OutlinedButton>('Disputar'));
    await tester.pumpAndSettle();
    // Confirmar sin escribir motivo: el comando no debe ejecutarse.
    await tester.tap(findButtonWithText<FilledButton>('Disputar'));
    await tester.pumpAndSettle();

    expect(repo.disputeCalls, 0);
  });

  testWidgets('pagar: escribe referencia, confirma y llama al repo', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      data: settlement(status: SettlementStatus.approved),
    );

    await tester.tap(findButtonWithText<FilledButton>('Marcar como pagada'));
    await tester.pumpAndSettle();
    expect(find.text('Marcar como pagada'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'TRX-9988');
    await tester.tap(findButtonWithText<FilledButton>('Pagar'));
    await tester.pumpAndSettle();

    expect(repo.payCalls, 1);
    expect(repo.lastPaymentReference, 'TRX-9988');
    expect(find.text('Aceptado. Se está procesando.'), findsOneWidget);
  });

  testWidgets('error de carga muestra el estado de error con reintento', (
    tester,
  ) async {
    await _pump(
      tester,
      data: settlement(),
      loader: () => Future.error(
        const ApiException(status: 500, title: 'Error', detail: 'Falló'),
      ),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('con la liquidación de la lista la muestra sin spinner', (
    tester,
  ) async {
    final pending = Completer<Settlement>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          carrierRepositoryProvider.overrideWithValue(FakeCarrierRepository()),
          carrierSettlementProvider(_id).overrideWith((ref) => pending.future),
        ],
        child: MaterialApp(
          home: CarrierSettlementDetailScreen(
            settlementId: _id,
            initial: settlement(status: SettlementStatus.submitted),
          ),
        ),
      ),
    );
    await tester.pump();

    // El detalle todavía no llegó, pero ya se ve la semilla de la lista.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Enviada'), findsOneWidget);

    // Llega la versión fresca y la reemplaza.
    pending.complete(settlement(status: SettlementStatus.approved));
    await tester.pumpAndSettle();
    expect(find.text('Aprobada'), findsOneWidget);
  });
}
