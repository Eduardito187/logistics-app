import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/features/driver/presentation/active_delivery_screen.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/failed_delivery_screen.dart';
import 'package:logistics_app/features/driver/presentation/pod_screen.dart';
import 'package:logistics_app/features/driver/presentation/report_issue_screen.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_map.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_sheet.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_status_card.dart';

import '../../../support/screen_sizes.dart';
import '../support/driver_test_support.dart';

// Entrega en curso (estilo app de delivery): mapa, tarjeta de estado arriba,
// hoja con cliente/teléfono/dirección/productos y botones del paso al pie.
// "Ayuda" sin chat: llamar, navegar y reportar (no se pudo entregar,
// problema del vehículo).

final _stop = buildStop(
  sequence: 2,
  shipmentId: 'ship-9',
  customerName: 'Ana Pérez',
  orderReference: 'PED-9',
  address: 'Av. Banzer 123',
  etaAt: DateTime(2026, 10, 15, 14, 5),
  lat: -17.78,
  lng: -63.18,
  status: DriverRouteStopStatus.pending,
);

DriverRoute _route({
  DriverRouteStop? current,
  int completed = 1,
  List<DriverRouteStop>? stops,
}) => buildRoute(
  totalStops: 5,
  completedStops: completed,
  stopsRemaining: 5 - completed,
  currentStop: current,
  stops: stops ?? [_stop],
);

Shipment _shipment({String? phone = '+591 70000001'}) => Shipment(
  id: 'ship-9',
  source: OrderSource.store,
  externalId: 'PED-9',
  customerName: 'Ana Pérez',
  customerPhone: phone,
  addressText: 'Av. Banzer 123',
  addressReference: 'Portón verde',
  addressConfidenceScore: 90,
  addressConfidenceLevel: AddressConfidenceLevel.high,
  status: ShipmentStatus.planned,
  lines: const [
    ShipmentLine(
      id: 'l1',
      sku: 'SKU-TV55',
      productName: 'Televisor 55" 4K',
      quantity: 1,
    ),
    ShipmentLine(
      id: 'l2',
      sku: 'SKU-SOP',
      productName: 'Soporte de pared',
      quantity: 2,
    ),
  ],
);

List<Object> _overrides({
  DriverRoute? route,
  Shipment? shipment,
  DeliveryStatus delivery = DeliveryStatus.inTransit,
  GpsFix? fix,
  RouteTilePrefetcher? prefetcher,
}) => [
  ...gateBase(
    route: route ?? _route(current: _stop),
    prefetcher: prefetcher,
  ),
  if (fix != null) deliveryDriverFixProvider.overrideWith((ref) async => fix),
  shipmentDetailProvider.overrideWith(
    (ref, id) async => shipment ?? _shipment(),
  ),
  deliveryStateProvider.overrideWith(
    (ref, id) async => buildDelivery(shipmentId: id, status: delivery),
  ),
];

Future<void> _pump(WidgetTester tester, {List<Object>? overrides}) async {
  await pumpScoped(
    tester,
    overrides: overrides ?? _overrides(),
    child: const ActiveDeliveryScreen(),
    tall: true,
  );
}

/// Expande la hoja de la entrega arrastrándola hacia arriba.
Future<void> _expandSheet(WidgetTester tester) async {
  await tester.drag(find.text('Entrega'), const Offset(0, -900));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('currentStopOf', () {
    test('usa la parada actual del backend', () {
      expect(currentStopOf(_route(current: _stop))?.id, _stop.id);
    });

    test('sin parada actual toma la primera pendiente por secuencia', () {
      final s1 = buildStop(sequence: 3, shipmentId: 'a');
      final s2 = buildStop(sequence: 1, shipmentId: 'b');
      final done = buildStop(
        sequence: 0,
        shipmentId: 'c',
        status: DriverRouteStopStatus.completed,
      );
      expect(currentStopOf(_route(stops: [s1, done, s2]))?.shipmentId, 'b');
    });

    test('sin pendientes devuelve null', () {
      final done = buildStop(status: DriverRouteStopStatus.completed);
      expect(currentStopOf(_route(stops: [done])), isNull);
    });
  });

  testWidgets('camión exactamente en la parada: el mapa no se rompe', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      overrides: [
        ..._overrides(),
        // Misma coordenada que la parada: antes daba zoom infinito.
        deliveryDriverFixProvider.overrideWith(
          (ref) async => const GpsFix(lat: -17.78, lng: -63.18),
        ),
      ],
      child: const ActiveDeliveryScreen(),
      tall: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Entregar pedido'), findsOneWidget);
  });

  testWidgets('muestra el estado, el cliente, el teléfono y la dirección', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Parada 2 de 5'), findsOneWidget);
    expect(find.text('Llegada 14:05'), findsOneWidget);
    expect(find.text('En camino a Ana Pérez'), findsOneWidget);
    expect(find.byType(RouteProgressBar), findsOneWidget);

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Cliente · Pedido PED-9'), findsOneWidget);
    expect(find.text('+591 70000001'), findsOneWidget);
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('Av. Banzer 123\nPortón verde'), findsOneWidget);
    expect(find.text('Navegar'), findsOneWidget);
  });

  testWidgets('el pedido lista los productos con SKU y cantidad', (
    tester,
  ) async {
    await _pump(tester);
    await _expandSheet(tester);

    expect(find.text('Pedido'), findsOneWidget);
    expect(find.text('3 productos'), findsOneWidget);
    expect(find.text('Televisor 55" 4K'), findsOneWidget);
    expect(find.text('SKU-TV55'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
  });

  testWidgets('sin teléfono no muestra la fila ni "Llamar"', (tester) async {
    await _pump(
      tester,
      overrides: _overrides(shipment: _shipment(phone: null)),
    );

    expect(find.text('Teléfono'), findsNothing);
    expect(find.text('Llamar'), findsNothing);
  });

  testWidgets('en curso: entregar, escanear bultos y no se pudo', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Entregar pedido'), findsOneWidget);
    expect(find.text('Escanear bultos'), findsOneWidget);
    expect(find.text('No se pudo'), findsOneWidget);

    await tester.tap(find.text('Entregar pedido'));
    await tester.pumpAndSettle();
    expect(find.byType(PodScreen), findsOneWidget);
    // La foto de la entrega es obligatoria.
    expect(find.text('3. Foto de entrega (obligatoria)'), findsOneWidget);
  });

  testWidgets('"No se pudo" abre la entrega fallida', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('No se pudo'));
    await tester.pumpAndSettle();

    expect(find.byType(FailedDeliveryScreen), findsOneWidget);
  });

  testWidgets('entrega cerrada: ofrece pasar a la siguiente', (tester) async {
    await _pump(
      tester,
      overrides: _overrides(delivery: DeliveryStatus.delivered),
    );

    expect(find.text('Siguiente entrega'), findsOneWidget);
    expect(find.text('Entregar pedido'), findsNothing);
  });

  testWidgets('Ayuda: llamar, navegar y reportar inconvenientes, sin chat', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Ayuda'));
    await tester.pumpAndSettle();

    expect(find.text('Ayuda con esta entrega'), findsOneWidget);
    expect(find.text('Llamar al cliente'), findsOneWidget);
    expect(find.text('Abrir en la app de mapas'), findsOneWidget);
    expect(find.text('Reportar un inconveniente'), findsOneWidget);
    expect(find.text('No se pudo entregar'), findsOneWidget);
    expect(find.text('Problema con el vehículo'), findsOneWidget);
    expect(find.textContaining('chat'), findsNothing);

    await tester.tap(find.text('No se pudo entregar'));
    await tester.pumpAndSettle();
    expect(find.byType(FailedDeliveryScreen), findsOneWidget);
  });

  testWidgets('sin paradas pendientes: ruta completada', (tester) async {
    final done = buildStop(status: DriverRouteStopStatus.completed);
    await _pump(
      tester,
      overrides: _overrides(route: _route(completed: 5, stops: [done])),
    );

    expect(find.text('Ruta completada'), findsOneWidget);
    expect(find.text('Ver ruta del día'), findsOneWidget);
  });

  testOnScreens('sin desbordes con letra grande', (tester, screen) async {
    await pumpScoped(
      tester,
      overrides: _overrides(),
      child: withTextScale(const ActiveDeliveryScreen()),
    );

    expect(find.text('Entregar pedido'), findsOneWidget);
    expect(find.text('Ayuda'), findsOneWidget);
    // El botón principal queda dentro de la pantalla.
    final button = tester.getRect(find.text('Entregar pedido'));
    expect(button.bottom, lessThanOrEqualTo(screen.size.height));
  });

  group('datos nuevos del backend', () {
    final enriched = buildStop(
      sequence: 2,
      shipmentId: 'ship-9',
      customerName: 'Ana Pérez',
      status: DriverRouteStopStatus.pending,
      lat: -17.78,
      lng: -63.18,
      customerPhone: '+591 71111111',
      addressReference: 'Casa celeste',
      address: 'Calle 3',
      items: const [
        Items3(
          sku: 'SKU-A',
          name: 'Lavadora 9 kg',
          quantity: 1,
          imageUrl: 'https://cdn.example.com/lavadora.jpg',
        ),
      ],
    );

    testWidgets('teléfono, indicaciones y productos salen de la parada', (
      tester,
    ) async {
      await _pump(
        tester,
        overrides: _overrides(
          route: _route(current: enriched, stops: [enriched]),
          shipment: _shipment(phone: '+591 70000001'),
        ),
      );
      await _expandSheet(tester);

      expect(find.text('+591 71111111'), findsOneWidget); // de la parada
      expect(find.text('+591 70000001'), findsNothing);
      expect(find.text('Calle 3\nCasa celeste'), findsOneWidget);
      expect(find.text('Lavadora 9 kg'), findsOneWidget);
      expect(find.text('SKU-A'), findsOneWidget);
      // La foto se pide decodificada chica (memoria en teléfonos de 1 GB).
      final image = tester.widget<Image>(find.byType(Image).last);
      expect(image.image, isA<ResizeImage>());
      expect(find.byType(ProductTile), findsOneWidget);
    });

    test('la geometría GeoJSON [lng, lat] se convierte a puntos del mapa', () {
      final points = routeGeometryPoints(
        const RouteGeometry(
          type: RouteGeometryType.lineString,
          coordinates: [
            [-63.18, -17.78],
            [-63.17, -17.77],
            [1],
          ],
          distanceMeters: 1200,
          durationSeconds: 300,
        ),
      );
      expect(points, hasLength(2));
      expect(points.first.latitude, -17.78);
      expect(points.first.longitude, -63.18);
      expect(routeGeometryPoints(null), isEmpty);
    });

    testWidgets('Ayuda → "Otro inconveniente" abre el reporte', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Ayuda'));
      await tester.pumpAndSettle();
      expect(find.text('Otro inconveniente'), findsOneWidget);

      await tester.tap(find.text('Otro inconveniente'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportIssueScreen), findsOneWidget);
    });
  });

  group('navegación en la entrega', () {
    // Trazo por calles hacia la parada (-17.78, -63.18): al este y al norte.
    const geometry = RouteGeometry(
      type: RouteGeometryType.lineString,
      coordinates: [
        [-63.190, -17.790],
        [-63.180, -17.790],
        [-63.180, -17.780],
      ],
      distanceMeters: 2200,
      durationSeconds: 440, // 5 m/s
    );

    DriverRoute withGeometry() => buildRoute(
      totalStops: 5,
      completedStops: 1,
      stopsRemaining: 4,
      currentStop: _stop,
      stops: [_stop],
      routeGeometry: geometry,
    );

    testWidgets(
      'sin posición del camión no muestra distancia ni botón seguir',
      (tester) async {
        await _pump(tester);

        expect(find.textContaining('Faltan'), findsNothing);
        expect(find.byTooltip('Seguir camión'), findsNothing);
        expect(find.byTooltip('Centrar'), findsOneWidget);
      },
    );

    testWidgets('muestra distancia y tiempo restantes sobre el trazo', (
      tester,
    ) async {
      await _pump(
        tester,
        overrides: _overrides(
          route: withGeometry(),
          fix: const GpsFix(lat: -17.790, lng: -63.190),
        ),
      );

      // ~1,06 km + ~1,11 km por calles a 5 m/s ≈ 7 min.
      expect(find.text('Faltan 2,2 km · 7 min'), findsOneWidget);
      expect(find.text('Fuera de ruta'), findsNothing);
    });

    testWidgets('sin trazo usa la línea recta corregida', (tester) async {
      await _pump(
        tester,
        overrides: _overrides(fix: const GpsFix(lat: -17.790, lng: -63.180)),
      );

      // 1,1 km en recta × 1,4 ≈ 1,5 km a 25 km/h ≈ 4 min.
      expect(find.text('Faltan 1,5 km · 4 min'), findsOneWidget);
    });

    testWidgets(
      'GPS imposible (emulador en California) se ignora: sin "Faltan" ni '
      '"Fuera de ruta" y el mapa encuadra la ruta del día',
      (tester) async {
        await _pump(
          tester,
          overrides: _overrides(
            route: withGeometry(),
            fix: const GpsFix(lat: 37.42, lng: -122.08),
          ),
        );

        expect(find.textContaining('Faltan'), findsNothing);
        expect(find.text('Fuera de ruta'), findsNothing);
        expect(find.byTooltip('Seguir camión'), findsNothing);
        final controller = MapController.maybeOf(
          tester.element(find.byType(MarkerLayer).first),
        )!;
        expect(controller.camera.center.latitude, closeTo(-17.785, 0.05));
        expect(controller.camera.zoom, greaterThan(10));
      },
    );

    testWidgets('los botones + y − cambian el zoom', (tester) async {
      await _pump(tester, overrides: _overrides(route: withGeometry()));
      final controller = MapController.maybeOf(
        tester.element(find.byType(MarkerLayer).first),
      )!;
      final before = controller.camera.zoom;

      await tester.tap(find.byTooltip('Acercar'));
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, closeTo(before + 1, 1e-6));

      await tester.tap(find.byTooltip('Alejar'));
      await tester.tap(find.byTooltip('Alejar'));
      await tester.pumpAndSettle();
      expect(controller.camera.zoom, closeTo(before - 1, 1e-6));
    });

    testWidgets('a más de 150 m del trazo avisa "Fuera de ruta"', (
      tester,
    ) async {
      await _pump(
        tester,
        overrides: _overrides(
          route: withGeometry(),
          fix: const GpsFix(lat: -17.800, lng: -63.185),
        ),
      );

      expect(find.text('Fuera de ruta'), findsOneWidget);
      expect(find.textContaining('Faltan'), findsOneWidget);
    });

    testWidgets('modo seguir: se activa con el botón y se apaga al arrastrar', (
      tester,
    ) async {
      await _pump(
        tester,
        overrides: _overrides(
          route: withGeometry(),
          fix: const GpsFix(lat: -17.785, lng: -63.180),
        ),
      );

      expect(find.byTooltip('Seguir camión'), findsOneWidget);
      await tester.tap(find.byTooltip('Seguir camión'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Dejar de seguir'), findsOneWidget);
      final controller = MapController.maybeOf(
        tester.element(find.byType(MarkerLayer).first),
      )!;
      expect(controller.camera.center.latitude, closeTo(-17.785, 1e-6));
      expect(controller.camera.zoom, greaterThanOrEqualTo(17));

      // Arrastrar el mapa con el dedo apaga el modo seguir.
      final map = tester.getRect(find.byType(FlutterMap));
      await tester.dragFrom(
        Offset(map.center.dx, map.top + map.height * 0.55),
        const Offset(120, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Seguir camión'), findsOneWidget);
    });

    testWidgets(
      'tras abrir precarga (diferida) los tiles de las paradas y el trazo',
      (tester) async {
        final requested = <List<LatLng>>[];
        final keys = <String?>[];
        await _pump(
          tester,
          overrides: _overrides(
            route: withGeometry(),
            prefetcher: (points, {routeKey}) async {
              requested.add(points);
              keys.add(routeKey);
            },
          ),
        );

        // Diferida: no compite con la transición ni con los tiles visibles.
        expect(requested, isEmpty);
        await tester.pump(const Duration(seconds: 1));

        expect(requested, hasLength(1));
        // 1 parada + 3 puntos del trazo.
        expect(requested.single, hasLength(4));
        expect(requested.single.first, const LatLng(-17.78, -63.18));
        expect(routePrefetchPoints(withGeometry()), requested.single);
        // Clave estable (id de la ruta): el core la precarga una sola vez.
        expect(keys, [withGeometry().id]);
      },
    );
  });
}
