import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/settlement_status.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_assignment_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_cheapest_tariff_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_deliver_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_pickup_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_settlement_detail_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_settlements_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_tariff_screen.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';

import '../../../support/button_finders.dart';
import '../../../support/fake_code_scanner.dart';
import '../../../support/screen_sizes.dart';
import '../carrier_fixtures.dart';
import '../carrier_scan_harness.dart';
import '../carrier_test_harness.dart';

// Layout del transportista en los 4 tamaños (teléfono chico 320x568 hasta tablet
// horizontal 1280x800) con letra grande 1.3x (el tope de la app). Un desborde
// hace fallar el test solo; además se verifica que en tablets el contenido no
// se estire de borde a borde.

/// Monta [home] con letra 1.3x y el transportista ya elegido.
Future<void> _pumpWithCarrier(
  WidgetTester tester,
  Widget home, {
  FakeCarrierRepository? repo,
}) async {
  final container = ProviderContainer(
    overrides: [
      carrierRepositoryProvider.overrideWithValue(
        repo ?? FakeCarrierRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(selectedCarrierProvider.notifier).select(carrier());
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: withTextScale(home)),
    ),
  );
  await tester.pumpAndSettle();
}

/// En tablets el ancho del contenido queda acotado.
void _expectBoundedWidth(WidgetTester tester, Finder finder, double max) {
  expect(tester.getSize(finder.first).width, lessThanOrEqualTo(max));
}

void main() {
  testOnScreens('recoger: vacío y con bultos sin desbordes', (
    tester,
    screen,
  ) async {
    final loadScan = FakeRecordLoadScan();
    await pumpCarrierScanScreen(
      tester,
      withTextScale(const CarrierPickupScreen()),
      scanner: FakeCodeScanner([validLabelQr(), validLabelQr()]),
      loadScan: loadScan,
    );
    expect(find.text('Sin bultos recogidos'), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      await tester.tap(findButtonWithText<FilledButton>('Escanear bulto'));
      await tester.pumpAndSettle();
    }

    expect(loadScan.requests, hasLength(2));
    expect(find.text(vectorSku), findsNWidgets(2));
    _expectBoundedWidth(
      tester,
      findButtonWithText<FilledButton>('Escanear bulto'),
      AppBreakpoints.maxContentWidth,
    );
  });

  testOnScreens('entregar: con una entrega sin desbordes', (
    tester,
    screen,
  ) async {
    await pumpCarrierScanScreen(
      tester,
      withTextScale(const CarrierDeliverScreen()),
      scanner: FakeCodeScanner([validLabelQr(), 'CONF-1']),
    );
    expect(find.text('Sin entregas registradas'), findsOneWidget);

    await tester.tap(findButtonWithText<FilledButton>('Registrar entrega'));
    await tester.pumpAndSettle();

    expect(find.text(vectorSku), findsOneWidget);
    _expectBoundedWidth(
      tester,
      findButtonWithText<FilledButton>('Registrar entrega'),
      AppBreakpoints.maxContentWidth,
    );
  });

  testOnScreens('liquidaciones: lista con varios estados', (
    tester,
    screen,
  ) async {
    await _pumpWithCarrier(
      tester,
      const CarrierSettlementsScreen(),
      repo: FakeCarrierRepository(
        onListSettlements: (_) async => [
          for (final status in SettlementStatus.$valuesDefined)
            settlement(id: status.name, status: status, amountCents: 987654321),
        ],
      ),
    );

    // Lista perezosa: en teléfonos chicos la última tarjeta está fuera de vista.
    await tester.scrollUntilVisible(find.text('En disputa'), 200);
    expect(find.text('En disputa'), findsOneWidget);
    expect(find.textContaining('Bs '), findsWidgets);
  });

  testOnScreens('elegir transportista: lista sin desbordes', (
    tester,
    screen,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          carrierRepositoryProvider.overrideWithValue(
            FakeCarrierRepository(
              onListCarriers: () async => [
                carrier(),
                carrier(id: 'c2', name: 'Transportes del Oriente Boliviano'),
              ],
            ),
          ),
        ],
        child: MaterialApp(
          home: withTextScale(const CarrierSettlementsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elige tu transportista'), findsOneWidget);
    expect(find.text('Transportes del Oriente Boliviano'), findsOneWidget);
  });

  testOnScreens('detalle de liquidación con todas las filas y acciones', (
    tester,
    screen,
  ) async {
    await _pumpWithCarrier(
      tester,
      const CarrierSettlementDetailScreen(settlementId: 's1'),
      repo: FakeCarrierRepository(
        onGetSettlement: (_) async => settlement(
          status: SettlementStatus.submitted,
          amountCents: 987654321,
          carrierName: 'Transportes del Oriente Boliviano',
          disputeReason: 'Faltaron dos bultos en la entrega del lunes',
          paymentReference: 'TRF-2026-000123456',
        ),
      ),
    );

    expect(find.text('Motivo de disputa'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Disputar'), 200);
    expect(findButtonWithText<FilledButton>('Aprobar'), findsOneWidget);
    _expectBoundedWidth(
      tester,
      findButtonWithText<FilledButton>('Aprobar'),
      AppBreakpoints.maxContentWidth,
    );
  });

  testOnScreens('tarifas por corredor: formulario y resultado', (
    tester,
    screen,
  ) async {
    await _pumpWithCarrier(
      tester,
      const CarrierTariffScreen(),
      repo: FakeCarrierRepository(onGetTariff: () async => tariff()),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Origen (código)'),
      'LPB',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino (código)'),
      'SCZ',
    );
    final button = findButtonWithText<FilledButton>('Consultar tarifa');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Tarifa vigente'), findsOneWidget);
    _expectBoundedWidth(tester, button, AppBreakpoints.maxFormWidth);
  });

  testOnScreens('asignación por volumen: formulario y resultado', (
    tester,
    screen,
  ) async {
    await _pumpWithCarrier(
      tester,
      const CarrierAssignmentScreen(),
      repo: FakeCarrierRepository(
        onAssignForVolume: () async =>
            assignment(volumeM3: 1234.75, tariffValue: tariff()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Origen (código)'),
      'LPB',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino (código)'),
      'SCZ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Volumen (m³)'),
      '1234.75',
    );
    final button = findButtonWithText<FilledButton>('Calcular asignación');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Vehículo sugerido'), findsOneWidget);
    _expectBoundedWidth(tester, button, AppBreakpoints.maxFormWidth);
  });

  testOnScreens('tarifa más barata: formulario y resultado', (
    tester,
    screen,
  ) async {
    await _pumpWithCarrier(
      tester,
      const CarrierCheapestTariffScreen(),
      repo: FakeCarrierRepository(onCheapestTariff: () async => tariff()),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Origen (código)'),
      'LPB',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Destino (código)'),
      'SCZ',
    );
    final button = findButtonWithText<FilledButton>('Buscar más barata');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Vigente desde 2026-01-15'), findsOneWidget);
    _expectBoundedWidth(tester, button, AppBreakpoints.maxFormWidth);
  });
}
