import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/pickup_pod_screen.dart';

import '../store_fixtures.dart';
import '../store_test_harness.dart';
import '../../../support/button_finders.dart';

// Prueba de entrega en mostrador (POD): gating por confirmación del cliente y la
// lista de bultos. Los flujos escaneo -> entrega (con `FakeCodeScanner`) están
// en pickup_pod_scan_test.dart.

final _shipment = shipment(
  customerName: 'Ana Pérez',
  customerDocumentId: '12345678',
  customerPhone: '70000000',
);

Future<void> _pump(
  WidgetTester tester, {
  List<UnitTracking> units = const [],
}) async {
  // Superficie alta: la lista es perezosa y la lista de bultos queda debajo
  // del pie fijo en 800x600.
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        shipmentUnitsProvider(_shipment.id).overrideWith((ref) async => units),
      ],
      child: MaterialApp(home: PickupPodScreen(shipment: _shipment)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra los datos del cliente del envío', (tester) async {
    await _pump(tester);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Pedido DM-260012345'), findsOneWidget);
    expect(find.text('Documento: 12345678'), findsOneWidget);
    expect(find.text('Teléfono: 70000000'), findsOneWidget);
  });

  testWidgets('sin confirmación: avisa y deshabilita el botón de entregar', (
    tester,
  ) async {
    await _pump(tester, units: [unit(unitId: 'unit-1')]);

    expect(
      find.text('Primero captura la confirmación del cliente.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Escanear y entregar producto'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('al capturar la confirmación se habilita el botón', (
    tester,
  ) async {
    await _pump(tester, units: [unit(unitId: 'unit-1')]);

    await tester.enterText(
      find.widgetWithText(TextField, 'QR del cliente o documento'),
      'CI-12345678',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Primero captura la confirmación del cliente.'),
      findsNothing,
    );
    final button = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Escanear y entregar producto'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('lista los productos con el contador de entregados', (
    tester,
  ) async {
    await _pump(
      tester,
      units: [
        unit(
          unitId: 'unit-1',
          label: 'A1',
          sku: 'TV-55',
          productName: 'Televisor 55"',
        ),
        unit(unitId: 'unit-2'),
      ],
    );

    expect(find.text('Entregados 0 de 2 producto(s).'), findsOneWidget);
    // Foto, nombre y código del producto; sin dato, el id abreviado.
    expect(find.text('Televisor 55"'), findsOneWidget);
    expect(find.text('TV-55'), findsOneWidget);
    expect(find.textContaining('Producto '), findsOneWidget);
    expect(find.text('Pendiente'), findsNWidgets(2));
  });

  testWidgets('sin bultos muestra 0 de 0', (tester) async {
    await _pump(tester);
    expect(find.text('Entregados 0 de 0 producto(s).'), findsOneWidget);
  });
}
