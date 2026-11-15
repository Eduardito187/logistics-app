import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/lookup/data/order_lookup_data_source.dart';
import 'package:logistics_app/features/lookup/domain/order_stage.dart';
import 'package:logistics_app/features/lookup/presentation/lookup_routes.dart';
import 'package:logistics_app/features/lookup/presentation/order_lookup_screen.dart';

import '../../support/fake_code_scanner.dart';
import '../../support/fake_label_resolver.dart';

// "Consultar pedido": de TODOS los roles y solo informativa. La etapa la
// calcula el servidor; la app la traduce y dice a cuántas paradas está.

OrderLookupItem _order({
  String externalId = 'SO-900001',
  String customerName = 'María Quispe',
  OrderLookupStage stage = OrderLookupStage.onTheWay,
  int? stopsBefore,
  String? plate,
  bool canProcess = true,
  DeliveryMode deliveryMode = DeliveryMode.homeDelivery,
}) => OrderLookupItem.fromJson({
  'id': 'ship-1',
  'source': 'SAP',
  'external_id': externalId,
  'customer_name': customerName,
  'address_text': 'Av. 6 de Agosto 2170, La Paz',
  'address_confidence_score': 70,
  'address_confidence_level': 'HIGH',
  'status': 'IN_EXECUTION',
  'delivery_mode': deliveryMode.json,
  'lines': [
    {'id': 'l1', 'sku': 'COL-QUEEN', 'product_name': 'Colchón', 'quantity': 2},
  ],
  'progress': {'loaded_at': '2026-11-14T09:30:00-04:00'},
  'order_reference': externalId,
  'destination_node': null,
  'tracking': {
    'stage': stage.json,
    'stops_before': stopsBefore,
    'eta_at': null,
    'vehicle_plate': plate,
    'current_node': null,
  },
  'can_process': canProcess,
});

class _FakeLookup implements OrderLookupDataSource {
  _FakeLookup(this.results, {this.error});

  final List<OrderLookupItem> results;
  final Object? error;
  final List<String> queries = [];

  @override
  Future<List<OrderLookupItem>> search(String query) async {
    queries.add(query);
    final e = error;
    if (e != null) throw e;
    return results;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeLookup fake, {
  String? initialQuery,
  FakeCodeScanner? scanner,
  FakeLabelResolver? resolver,
}) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderLookupDataSourceProvider.overrideWithValue(fake),
        if (scanner != null)
          codeScannerProvider.overrideWithValue(scanner.call),
        if (resolver != null) labelResolverProvider.overrideWithValue(resolver),
      ],
      child: MaterialApp(home: OrderLookupScreen(initialQuery: initialQuery)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('textos', () {
    test('a cuántas paradas está', () {
      expect(stopsBeforeText(null), isNull);
      expect(stopsBeforeText(0), 'Es la próxima parada del camión');
      expect(stopsBeforeText(1), 'Está a 1 parada de llegar');
      expect(stopsBeforeText(3), 'Está a 3 paradas de llegar');
    });

    test('etapas en palabras para el cliente', () {
      expect(orderStageLabel(OrderLookupStage.onTheWay), 'En camino');
      expect(
        orderStageLabel(OrderLookupStage.atStore),
        'En la tienda, listo para retirar',
      );
      expect(orderStageClosed(OrderLookupStage.delivered), isTrue);
      expect(orderStageClosed(OrderLookupStage.onTheWay), isFalse);
    });

    test('de qué ciudad a qué ciudad va, solo si cambia', () {
      expect(orderTripText('cochabamba', 'la_paz'), 'Cochabamba → La Paz');
      expect(orderTripText('potosi', 'santa_cruz'), 'Potosí → Santa Cruz');
      expect(orderTripText('la_paz', 'la_paz'), isNull);
      expect(orderTripText(null, 'la_paz'), isNull);
    });
  });

  test('"Consultar pedido" es una tarea de TODOS los roles', () {
    expect(lookupTasks.single.roles, UserRole.values.toSet());
  });

  testWidgets('al abrir invita a escanear o buscar', (tester) async {
    await _pump(tester, _FakeLookup(const []));

    expect(find.text('Escaneá o buscá un pedido'), findsOneWidget);
  });

  testWidgets('muestra la etapa del servidor y a cuántas paradas está', (
    tester,
  ) async {
    final fake = _FakeLookup([_order(stopsBefore: 3, plate: '904U10')]);
    await _pump(tester, fake);

    await tester.enterText(find.byType(TextField), 'SO-900001');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(fake.queries, ['SO-900001']);
    expect(find.text('Pedido SO-900001'), findsOneWidget);
    expect(find.text('María Quispe'), findsOneWidget);
    expect(find.text('En camino'), findsOneWidget);
    expect(find.text('Está a 3 paradas de llegar'), findsOneWidget);
    expect(find.text('Camión 904U10'), findsOneWidget);
    expect(find.text('Entregado: pendiente'), findsOneWidget);
    expect(find.text('Solo consulta'), findsNothing);
  });

  testWidgets('un pedido fuera del alcance se ve como "Solo consulta"', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeLookup([_order(canProcess: false)]),
      initialQuery: 'SO-900001',
    );

    expect(find.text('Pedido SO-900001'), findsOneWidget);
    expect(find.text('Solo consulta'), findsOneWidget);
  });

  testWidgets('en la tienda: listo para retirar', (tester) async {
    await _pump(
      tester,
      _FakeLookup([
        _order(
          stage: OrderLookupStage.atStore,
          deliveryMode: DeliveryMode.storePickup,
        ),
      ]),
      initialQuery: 'SO-900001',
    );

    expect(find.text('En la tienda, listo para retirar'), findsOneWidget);
    expect(find.text('El cliente lo retira en la tienda'), findsOneWidget);
    expect(find.text('Llegó a la tienda: pendiente'), findsOneWidget);
  });

  testWidgets('abre ya buscando (lo que la tienda tenía escrito)', (
    tester,
  ) async {
    final fake = _FakeLookup([_order(externalId: 'DM-1')]);
    await _pump(tester, fake, initialQuery: 'DM-1');

    expect(fake.queries, ['DM-1']);
    expect(find.text('Pedido DM-1'), findsOneWidget);
  });

  testWidgets('sin resultados lo dice', (tester) async {
    await _pump(tester, _FakeLookup(const []), initialQuery: 'NADA');

    expect(find.text('Pedido no encontrado'), findsOneWidget);
  });

  testWidgets('escanear una etiqueta busca su pedido', (tester) async {
    final fake = _FakeLookup([_order(externalId: 'DM-7')]);
    await _pump(
      tester,
      fake,
      scanner: FakeCodeScanner(['LBL-1']),
      resolver: FakeLabelResolver(
        resolutions: {
          'LBL-1': const LabelResolution(
            labelId: 'LBL-1',
            resolved: true,
            unitId: 'u1',
            orderNumber: 'DM-7',
            sku: 'TV-55',
            productName: 'Televisor 55"',
          ),
        },
      ),
    );

    await tester.tap(find.byTooltip('Escanear etiqueta'));
    await tester.pumpAndSettle();

    expect(fake.queries, ['DM-7']);
    expect(find.text('Etiqueta escaneada'), findsOneWidget);
    expect(find.text('Televisor 55"'), findsOneWidget);
    expect(find.text('Pedido DM-7'), findsWidgets);
  });

  testWidgets('si falla la consulta igual muestra lo de la etiqueta', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeLookup(const [], error: const ApiException(status: 500, title: 'x')),
      scanner: FakeCodeScanner(['LBL-1']),
      resolver: FakeLabelResolver(
        resolutions: {
          'LBL-1': const LabelResolution(
            labelId: 'LBL-1',
            resolved: true,
            unitId: 'u1',
            orderNumber: 'SCZ-1',
            productName: 'Heladera',
          ),
        },
      ),
    );

    await tester.tap(find.byTooltip('Escanear etiqueta'));
    await tester.pumpAndSettle();

    expect(find.text('Heladera'), findsOneWidget);
    expect(find.text('No se pudo consultar'), findsOneWidget);
  });

  testWidgets('etiqueta no reconocida: aviso', (tester) async {
    await _pump(
      tester,
      _FakeLookup(const []),
      scanner: FakeCodeScanner(['LBL-??']),
      resolver: FakeLabelResolver(),
    );

    await tester.tap(find.byTooltip('Escanear etiqueta'));
    await tester.pumpAndSettle();

    expect(find.text('Etiqueta no reconocida.'), findsOneWidget);
  });
}
