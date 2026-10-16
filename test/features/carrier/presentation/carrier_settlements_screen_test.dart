import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/carrier.dart';
import 'package:logistics_app/core/api/models/carrier_status.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/core/api/models/settlement.dart';
import 'package:logistics_app/core/api/models/settlement_status.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_settlements_screen.dart';

// Pantalla de liquidaciones del transportista. Se elige el transportista en la
// sesión (selectedCarrierProvider) y se override el provider de datos de la
// lista para renderizar sin Dio, cubriendo el estado con datos y el vacío.

const _carrier = Carrier(
  id: 'c1',
  name: 'Transportes Andinos',
  taxId: '123456',
  status: CarrierStatus.active,
  ratingCount: 0,
  documents: [],
);

const _settlement = Settlement(
  id: 's1',
  carrierId: 'c1',
  corridorFrom: 'LPZ',
  corridorTo: 'SCZ',
  corridorType: CorridorType.cdToCd,
  period: '2026-03',
  amountCents: 123456,
  currency: 'BOB',
  reference: 'REF-1',
  status: SettlementStatus.approved,
  documents: [],
);

Future<void> _pump(
  WidgetTester tester,
  Future<List<Settlement>> Function() load,
) async {
  final container = ProviderContainer(
    overrides: [
      carrierSettlementsProvider(_carrier.id).overrideWith((ref) => load()),
    ],
  );
  addTearDown(container.dispose);
  // El transportista ya está elegido: el guard muestra directamente la lista.
  container.read(selectedCarrierProvider.notifier).select(_carrier);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CarrierSettlementsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos lista las liquidaciones del transportista', (
    tester,
  ) async {
    await _pump(tester, () async => [_settlement]);

    expect(find.text('Mis liquidaciones'), findsOneWidget);
    expect(find.text('LPZ → SCZ'), findsOneWidget);
    expect(find.text('Periodo 2026-03'), findsOneWidget);
    expect(find.text('Aprobada'), findsOneWidget); // pastilla de estado
  });

  testWidgets('sin liquidaciones muestra el estado vacío', (tester) async {
    await _pump(tester, () async => const <Settlement>[]);

    expect(find.text('Sin liquidaciones'), findsOneWidget);
  });
}
