import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/delivery_mode.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_shipments_notifier.dart';
import 'package:logistics_app/features/store/presentation/counter_pickup_screen.dart';
import 'package:logistics_app/features/store/presentation/widgets/pickup_card.dart';
import 'package:logistics_app/features/store/presentation/widgets/pickup_label_sheet.dart';

import '../../../support/fake_code_scanner.dart';
import '../../../support/fake_label_resolver.dart';
import '../store_fixtures.dart';
import '../store_test_harness.dart';

// Lista de envíos para entrega en mostrador: estados con datos, vacío y
// error, y el pie de scroll infinito cuando el servidor tiene más páginas.

Future<FakeStoreShipments> _pump(
  WidgetTester tester,
  Future<List<Shipment>> Function() load, {
  bool hasMore = false,
  FakeCodeScanner? scanner,
  FakeLabelResolver? resolver,
}) async {
  final notifier = FakeStoreShipments(load, hasMore: hasMore);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        storeShipmentsPagedProvider.overrideWith(() => notifier),
        if (scanner != null)
          codeScannerProvider.overrideWithValue(scanner.call),
        if (resolver != null) labelResolverProvider.overrideWithValue(resolver),
      ],
      child: const MaterialApp(home: CounterPickupScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return notifier;
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Código del pedido'),
    text,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapScanLabel(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Escanear etiqueta'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('solo recojos de cliente: los traslados a tienda no aparecen', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => [
        shipment(
          customerName: 'Ana Pérez',
          deliveryMode: DeliveryMode.storePickup,
        ),
        shipment(
          id: 'ship-2',
          customerName: 'Traslado CD',
          deliveryMode: DeliveryMode.transfer,
        ),
      ],
    );

    expect(find.byType(PickupCard), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Traslado CD'), findsNothing);
  });

  testWidgets('los listos para retirar van arriba de los que están en camino', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => [
        // En camino primero en el backend, pero debe quedar ABAJO.
        shipment(
          id: 'ship-camino',
          customerName: 'En Camino',
          externalId: 'DM-1',
        ),
        shipment(
          id: 'ship-listo',
          customerName: 'Ya Llegó',
          externalId: 'DM-2',
          readyForPickupAt: DateTime(2026, 11, 16, 9, 30),
        ),
      ],
    );

    final cards = tester.widgetList<PickupCard>(find.byType(PickupCard));
    expect(cards.first.shipment.id, 'ship-listo');
    expect(cards.last.shipment.id, 'ship-camino');
    expect(find.textContaining('Listo para retirar'), findsOneWidget);
  });

  group('buscar por código del pedido', () {
    Future<List<Shipment>> two() async => [
      shipment(customerName: 'Ana Pérez', externalId: 'DM-1001'),
      shipment(
        id: 'ship-2',
        customerName: 'Luis Gómez',
        externalId: 'DM-2002',
        customerDocumentId: '7654321',
      ),
    ];

    testWidgets('filtra por código, sin importar mayúsculas', (tester) async {
      await _pump(tester, two);

      await _search(tester, 'dm-2002');

      expect(find.byType(PickupCard), findsOneWidget);
      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsNothing);
    });

    testWidgets('también encuentra por cliente o documento', (tester) async {
      await _pump(tester, two);

      await _search(tester, 'ana');
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Luis Gómez'), findsNothing);

      await _search(tester, '7654');
      expect(find.text('Luis Gómez'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsNothing);
    });

    testWidgets('sin coincidencias avisa y borrar vuelve a la lista', (
      tester,
    ) async {
      await _pump(tester, two);

      await _search(tester, 'NO-EXISTE');
      expect(find.text('Pedido no encontrado'), findsOneWidget);
      expect(find.byType(PickupCard), findsNothing);

      await tester.tap(find.byTooltip('Borrar búsqueda'));
      await tester.pumpAndSettle();
      expect(find.byType(PickupCard), findsNWidgets(2));
    });
  });

  group('escanear una etiqueta', () {
    Future<List<Shipment>> one() async => [
      shipment(
        customerName: 'Ana Pérez',
        externalId: 'DM-1001',
        customerPhone: '70000000',
      ),
      shipment(id: 'ship-2', customerName: 'Luis Gómez', externalId: 'DM-2'),
    ];

    testWidgets('muestra el pedido, el producto y el cliente a entregar', (
      tester,
    ) async {
      final scanner = FakeCodeScanner(['LBL-9']);
      await _pump(
        tester,
        one,
        scanner: scanner,
        resolver: FakeLabelResolver(
          resolutions: {
            'LBL-9': const LabelResolution(
              labelId: 'LBL-9',
              resolved: true,
              unitId: 'unit-1',
              shipmentId: 'ship-1',
              sku: 'TV-55',
              productName: 'Televisor 55"',
              orderNumber: 'DM-1001',
            ),
          },
        ),
      );

      await _tapScanLabel(tester);

      expect(scanner.requestedTitles, ['Escanear etiqueta']);
      expect(find.text('Pedido DM-1001'), findsWidgets);
      expect(find.text('Televisor 55"'), findsOneWidget);
      expect(find.text('SKU TV-55'), findsOneWidget);
      expect(find.text('Teléfono: 70000000'), findsOneWidget);
      expect(find.text('Entregar este pedido'), findsOneWidget);
    });

    testWidgets('pedido que no es de la tienda: lo dice y no ofrece entregar', (
      tester,
    ) async {
      await _pump(
        tester,
        one,
        scanner: FakeCodeScanner(['LBL-7']),
        resolver: FakeLabelResolver(
          resolutions: {
            'LBL-7': const LabelResolution(
              labelId: 'LBL-7',
              resolved: true,
              unitId: 'unit-x',
              shipmentId: 'ship-otro',
              orderNumber: 'DM-OTRO',
            ),
          },
        ),
      );

      await _tapScanLabel(tester);

      expect(find.text('Pedido DM-OTRO'), findsOneWidget);
      expect(
        find.text('Este pedido no figura entre los recojos de tu tienda.'),
        findsOneWidget,
      );
      expect(find.text('Entregar este pedido'), findsNothing);
    });

    testWidgets('etiqueta no reconocida o sin señal: aviso, sin hoja', (
      tester,
    ) async {
      await _pump(
        tester,
        one,
        scanner: FakeCodeScanner(['LBL-??', 'LBL-9']),
        resolver: FakeLabelResolver(),
      );

      await _tapScanLabel(tester);
      expect(find.text('Etiqueta no reconocida.'), findsOneWidget);
      expect(find.byType(PickupLabelSheet), findsNothing);
    });

    testWidgets('sin señal no se puede consultar la etiqueta', (tester) async {
      await _pump(
        tester,
        one,
        scanner: FakeCodeScanner(['LBL-9']),
        resolver: FakeLabelResolver(offline: true),
      );

      await _tapScanLabel(tester);

      expect(
        find.text('No se pudo consultar la etiqueta. Intentá de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('cancelar el escaneo no hace nada', (tester) async {
      await _pump(tester, one, scanner: FakeCodeScanner([null]));

      await _tapScanLabel(tester);

      expect(find.byType(PickupLabelSheet), findsNothing);
      expect(find.byType(PickupCard), findsNWidgets(2));
    });
  });

  testWidgets('con datos muestra una tarjeta por envío', (tester) async {
    await _pump(
      tester,
      () async => [
        shipment(customerName: 'Ana Pérez'),
        shipment(id: 'ship-2', customerName: 'Luis Gómez'),
      ],
    );

    expect(find.text('Recojo en tienda'), findsOneWidget);
    expect(find.byType(PickupCard), findsNWidgets(2));
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);
  });

  testWidgets('sin envíos muestra el estado vacío "Sin recojos"', (
    tester,
  ) async {
    await _pump(tester, () async => const <Shipment>[]);

    expect(find.text('Sin recojos'), findsOneWidget);
    expect(find.byType(PickupCard), findsNothing);
  });

  testWidgets('error de API muestra el estado de error con reintento', (
    tester,
  ) async {
    await _pump(
      tester,
      () async => throw const ApiException(
        status: 500,
        title: 'Error',
        detail: 'Servidor no disponible',
      ),
    );

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('sin más páginas no hay pie de "cargar más"', (tester) async {
    await _pump(tester, () async => [shipment()]);

    expect(find.text('Cargar más recojos'), findsNothing);
  });

  testWidgets('con más páginas el pie pide la siguiente y avisa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final notifier = await _pump(
      tester,
      () async => [shipment(), shipment(id: 'ship-2')],
      hasMore: true,
    );

    await tester.tap(find.text('Cargar más recojos'));
    await tester.pump();

    expect(notifier.loadMoreCalls, 1);
    expect(find.text('Cargando más recojos…'), findsOneWidget);
    expect(find.text('Cargar más recojos'), findsNothing);
  });

  testWidgets('llegar al final de la lista pide la página siguiente', (
    tester,
  ) async {
    final notifier = await _pump(
      tester,
      () async => [
        for (var i = 0; i < 20; i++)
          shipment(id: 'ship-$i', customerName: 'Cliente $i'),
      ],
      hasMore: true,
    );
    expect(notifier.loadMoreCalls, 0);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pump();

    expect(notifier.loadMoreCalls, greaterThan(0));
  });
}
