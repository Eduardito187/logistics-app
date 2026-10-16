import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/api/models/settlement_status.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/settlements_list.dart';

import '../../carrier_fixtures.dart';

// Lista de liquidaciones del transportista: datos, vacío y error.

Future<void> _pump(
  WidgetTester tester,
  Future<List<Settlement>> Function() load,
) async {
  final c = carrier();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        carrierSettlementsProvider(c.id).overrideWith((ref) => load()),
      ],
      child: MaterialApp(
        home: Scaffold(body: SettlementsList(carrier: c)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos lista corredor, periodo, monto y estado', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => [settlement(status: SettlementStatus.approved)],
    );

    expect(find.text('LPZ → SCZ'), findsOneWidget);
    expect(find.text('Periodo 2026-03'), findsOneWidget);
    expect(find.text('Aprobada'), findsOneWidget);
    expect(find.textContaining('Bs'), findsOneWidget);
  });

  testWidgets('sin liquidaciones muestra el estado vacío', (tester) async {
    await _pump(tester, () async => const <Settlement>[]);
    expect(find.text('Sin liquidaciones'), findsOneWidget);
  });

  testWidgets('error de API muestra el estado de error', (tester) async {
    await _pump(
      tester,
      () async => throw const ApiException(status: 500, title: 'Error'),
    );
    expect(find.text('No se pudo cargar'), findsOneWidget);
  });
}
