import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/features/driver/presentation/active_delivery_screen.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_map.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_sheet.dart';

import '../support/driver_test_support.dart';

// Rendimiento de la entrega en curso en teléfonos de 1 GB: con cada fix del
// GPS solo cambian el camión y "Faltan …"; el trazo, la hoja y el pie no se
// reconstruyen, y los productos del pedido van en una lista perezosa.

/// Posición del camión controlable desde el test.
class _FixSource extends Notifier<GpsFix?> {
  @override
  GpsFix? build() => const GpsFix(lat: -17.790, lng: -63.190);

  void move(GpsFix fix) => state = fix;
}

final _fixSource = NotifierProvider<_FixSource, GpsFix?>(_FixSource.new);

final _stop = buildStop(
  sequence: 2,
  shipmentId: 'ship-9',
  customerName: 'Ana Pérez',
  lat: -17.78,
  lng: -63.18,
);

// Trazo denso: 2 tramos rectos muestreados cada ~10 m (≈ 220 puntos).
final RouteGeometry _denseGeometry = RouteGeometry(
  type: RouteGeometryType.lineString,
  coordinates: [
    for (var i = 0; i <= 110; i++) [-63.190 + i * 0.0001 * 0.909, -17.790],
    for (var i = 1; i <= 110; i++) [-63.180, -17.790 + i * 0.0001 * 0.909],
  ],
  distanceMeters: 2200,
  durationSeconds: 400,
);

List<Object> _overrides(DriverRoute route) => [
  ...gateBase(route: route),
  deliveryDriverFixProvider.overrideWith((ref) async => ref.watch(_fixSource)),
  shipmentDetailProvider.overrideWith(
    (ref, id) async => Shipment(
      id: id,
      source: OrderSource.store,
      externalId: 'PED-9',
      customerName: 'Ana Pérez',
      addressText: 'Av. Banzer 123',
      addressConfidenceScore: 90,
      addressConfidenceLevel: AddressConfidenceLevel.high,
      status: ShipmentStatus.planned,
      lines: const [],
    ),
  ),
  deliveryStateProvider.overrideWith(
    (ref, id) async =>
        buildDelivery(shipmentId: id, status: DeliveryStatus.inTransit),
  ),
];

DriverRoute _route({DriverRouteStop? stop, RouteGeometry? geometry}) =>
    buildRoute(
      totalStops: 5,
      completedStops: 1,
      stopsRemaining: 4,
      currentStop: stop ?? _stop,
      stops: [stop ?? _stop],
      routeGeometry: geometry ?? _denseGeometry,
    );

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  testWidgets('con cada fix del GPS solo cambian el camión y lo que falta', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: _overrides(_route()),
      child: const ActiveDeliveryScreen(),
      tall: true,
    );

    final layerBefore = tester.widget(find.byType(PolylineLayer));
    final sheetBefore = tester.widget(find.byType(DeliverySheet));
    final distanceBefore = tester
        .widget<Text>(find.textContaining('Faltan'))
        .data;
    // El trazo dibujado está simplificado: 2 rectas → 3 vértices.
    expect(
      (layerBefore as PolylineLayer).polylines.single.points,
      hasLength(3),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ActiveDeliveryScreen)),
    );
    container
        .read(_fixSource.notifier)
        .move(const GpsFix(lat: -17.790, lng: -63.181));
    await tester.pumpAndSettle();

    // La capa del trazo y la hoja son la MISMA instancia: no se reconstruyen.
    expect(
      identical(tester.widget(find.byType(PolylineLayer)), layerBefore),
      isTrue,
    );
    expect(
      identical(tester.widget(find.byType(DeliverySheet)), sheetBefore),
      isTrue,
    );
    // Lo que falta sí se actualiza.
    expect(
      tester.widget<Text>(find.textContaining('Faltan')).data,
      isNot(distanceBefore),
    );
  });

  testWidgets('un pedido con muchos productos solo construye los visibles', (
    tester,
  ) async {
    final stop = buildStop(
      sequence: 2,
      shipmentId: 'ship-9',
      customerName: 'Ana Pérez',
      lat: -17.78,
      lng: -63.18,
      items: [
        for (var i = 0; i < 200; i++)
          Items3(sku: 'SKU-$i', name: 'Producto $i', quantity: 1),
      ],
    );
    await pumpScoped(
      tester,
      overrides: _overrides(_route(stop: stop)),
      child: const ActiveDeliveryScreen(),
      tall: true,
    );

    expect(find.text('200 productos'), findsOneWidget);
    expect(find.text('Producto 0'), findsOneWidget);
    final built = find.byType(ProductTile, skipOffstage: false).evaluate();
    expect(built.length, lessThan(200));
    expect(find.text('Producto 199', skipOffstage: false), findsNothing);
  });

  testWidgets('la foto del producto se decodifica chica sin deformarse', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProductTile(
            item: OrderItemView(
              sku: 'SKU-1',
              name: 'Lavadora',
              quantity: 1,
              imageUrl: 'https://example.com/a.jpg',
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final resize = image.image as ResizeImage;
    expect(resize.width, 168);
    expect(resize.height, 168);
    expect(resize.policy, ResizeImagePolicy.fit);
    expect(image.errorBuilder, isNotNull);
  });
}
