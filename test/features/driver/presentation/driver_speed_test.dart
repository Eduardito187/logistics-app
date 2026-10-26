import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/continuous_scanner.dart';
import 'package:logistics_app/features/driver/domain/repositories/driver_route_repository.dart';
import 'package:logistics_app/features/driver/domain/usecases/get_driver_route.dart';
import 'package:logistics_app/features/driver/presentation/active_delivery_screen.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_prefetch.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_tracking_autostart.dart';
import 'package:logistics_app/features/driver/presentation/controllers/locally_loaded_units.dart';
import 'package:logistics_app/features/driver/presentation/controllers/locally_settled_stops.dart';
import 'package:logistics_app/features/driver/presentation/driver_vehicle_gate.dart';
import 'package:logistics_app/features/driver/presentation/load_scan_screen.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_map.dart';
import 'package:logistics_app/features/driver/presentation/widgets/active_delivery/delivery_sheet.dart';
import 'package:logistics_app/features/driver/presentation/widgets/route_list.dart';

import '../support/driver_test_support.dart';
import '../support/fake_continuous_scanner.dart';

// Velocidad percibida del chofer: rastreo estable al refrescar la ruta, ruta
// en caché y precargada, avance optimista sin señal, menos requests y conteos
// de carga al día.

class _NoRepo implements DriverRouteRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Ruta del día falsa que cuenta los pedidos a "la red".
class _CountingGetDriverRoute extends GetDriverRoute {
  _CountingGetDriverRoute(this.route) : super(_NoRepo());

  final DriverRoute route;
  int calls = 0;

  @override
  Future<DriverRoute> call({
    required String vehicleId,
    required DateTime date,
  }) async {
    calls++;
    return route;
  }
}

final _a = buildStop(id: 'a', shipmentId: 'ship-a', sequence: 1);
final _b = buildStop(id: 'b', shipmentId: 'ship-b', sequence: 2);

DriverRoute _twoStops({
  DriverRouteStopStatus aStatus = DriverRouteStopStatus.pending,
}) => buildRoute(
  stops: [
    buildStop(id: 'a', shipmentId: 'ship-a', sequence: 1, status: aStatus),
    _b,
  ],
);

void main() {
  group('rastreo automático', () {
    Future<(ProviderContainer, FakeTruckTracking)> mount(
      WidgetTester tester,
      FutureOr<DriverRoute> Function() route,
    ) async {
      final container = ProviderContainer(
        overrides: [
          truckTrackingProvider.overrideWith(FakeTruckTracking.new),
          driverRouteProvider.overrideWith((ref) async => route()),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DriverTrackingAutostart(child: SizedBox()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tracking =
          container.read(truckTrackingProvider.notifier) as FakeTruckTracking;
      return (container, tracking);
    }

    testWidgets('refrescar la ruta NO apaga ni re-prende el rastreo', (
      tester,
    ) async {
      final (container, tracking) = await mount(tester, _twoStops);
      expect(tracking.startCount, 1);

      // Lo que hace la entrega en curso al volver de cada paso.
      container.invalidate(driverRouteProvider);
      await tester.pump();
      container.invalidate(driverRouteProvider);
      await tester.pumpAndSettle();

      expect(tracking.stopCount, 0);
      expect(tracking.startCount, 1);
      expect(tracking.state.shipmentId, 'ship-a');
    });

    testWidgets('con la ruta todavía cargando no detiene el rastreo', (
      tester,
    ) async {
      final never = Completer<DriverRoute>();
      final (_, tracking) = await mount(tester, () => never.future);

      expect(tracking.stopCount, 0);
      expect(tracking.startCount, 0);
    });

    testWidgets('otra pantalla con el rastreo ya andando no llama start', (
      tester,
    ) async {
      final (container, tracking) = await mount(tester, _twoStops);
      expect(tracking.startCount, 1);

      // Se monta el gate de otra pantalla (nuevo autostart).
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DriverTrackingAutostart(
              key: ValueKey('otra'),
              child: SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tracking.startCount, 1);
      expect(tracking.stopCount, 0);
    });

    testWidgets('una parada resuelta localmente re-apunta a la siguiente', (
      tester,
    ) async {
      final (container, tracking) = await mount(tester, _twoStops);
      container
          .read(locallySettledStopsProvider.notifier)
          .settle('a', DriverRouteStopStatus.completed);
      await tester.pumpAndSettle();

      expect(tracking.state.shipmentId, 'ship-b');
    });
  });

  group('assignedVehicleIdProvider', () {
    test('conserva el vehículo mientras la tripulación se recarga', () async {
      var calls = 0;
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          myCrewProvider.overrideWith((ref) async {
            calls++;
            if (calls > 1) {
              throw const ApiException(status: 0, title: 'sin red');
            }
            return buildMyCrew(vehicle: buildVehicle(id: 'v-7'));
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(assignedVehicleIdProvider, (_, _) {});
      await container.read(myCrewProvider.future);
      expect(container.read(assignedVehicleIdProvider), 'v-7');

      // Recarga que falla (sin señal): el vehículo no "desaparece".
      container.invalidate(myCrewProvider);
      expect(container.read(assignedVehicleIdProvider), 'v-7');
      await expectLater(
        container.read(myCrewProvider.future),
        throwsA(anything),
      );
      expect(container.read(assignedVehicleIdProvider), 'v-7');
    });
  });

  group('ruta en caché y precarga', () {
    List<Object> overrides(_CountingGetDriverRoute get) => [
      myCrewProvider.overrideWith((ref) async => buildMyCrew()),
      getDriverRouteProvider.overrideWithValue(get),
    ];

    testWidgets(
      'prefetchDriverDayIn pide tripulación y ruta y la deja en caché',
      (tester) async {
        final get = _CountingGetDriverRoute(_twoStops());
        final container = ProviderContainer(overrides: overrides(get).cast());
        addTearDown(container.dispose);

        await tester.runAsync(() => prefetchDriverDayIn(container));
        expect(get.calls, 1);
        // Sin nadie escuchando sigue viva (caché corta): la pantalla que abra
        // la ruta la ve al instante y sin otro request.
        await tester.pump(const Duration(seconds: 10));
        container.listen(driverRouteProvider, (_, _) {});
        expect(container.read(driverRouteProvider).hasValue, isTrue);
        expect(get.calls, 1);
      },
    );

    test('sin asignación la precarga no lanza ni pide la ruta', () async {
      final get = _CountingGetDriverRoute(buildEmptyRoute());
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          myCrewProvider.overrideWith(
            (ref) async =>
                throw const ApiException(status: 0, title: 'sin red'),
          ),
          getDriverRouteProvider.overrideWithValue(get),
        ],
      );
      addTearDown(container.dispose);

      await prefetchDriverDayIn(container);
      expect(get.calls, 0);
    });

    testWidgets('el gate pide la ruta aunque el permiso no esté concedido', (
      tester,
    ) async {
      final get = _CountingGetDriverRoute(buildEmptyRoute());
      await pumpScoped(
        tester,
        overrides: [
          locationServiceProvider.overrideWithValue(
            FakeLocationService(granted: false),
          ),
          truckTrackingProvider.overrideWith(FakeTruckTracking.new),
          ...overrides(get),
        ],
        child: DriverVehicleGate(
          title: 'Mi ruta',
          builder: (_, _) => const Text('contenido'),
        ),
        tall: true,
      );

      expect(find.text('contenido'), findsNothing);
      expect(get.calls, 1);
    });
  });

  group('paradas resueltas localmente', () {
    test('currentStopOf salta la resuelta y avanza a la siguiente', () {
      final route = _twoStops();
      expect(currentStopOf(route)?.id, 'a');
      expect(
        currentStopOf(route, {'a': DriverRouteStopStatus.completed})?.id,
        'b',
      );
      expect(
        currentStopOf(route, {
          'a': DriverRouteStopStatus.completed,
          'b': DriverRouteStopStatus.failed,
        }),
        isNull,
      );
      // La marcada en curso por el backend también se salta si se resolvió.
      final withCurrent = buildRoute(currentStop: _a, stops: [_a, _b]);
      expect(
        currentStopOf(withCurrent, {'a': DriverRouteStopStatus.completed})?.id,
        'b',
      );
    });

    test('reconcile quita lo que el backend ya devuelve resuelto', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locallySettledStopsProvider.notifier)
        ..settle('a', DriverRouteStopStatus.completed)
        ..settle('b', DriverRouteStopStatus.failed);

      // El backend todavía dice pendiente: se mantienen.
      notifier.reconcile(_twoStops());
      expect(container.read(locallySettledStopsProvider).keys, ['a', 'b']);

      notifier.reconcile(_twoStops(aStatus: DriverRouteStopStatus.completed));
      expect(container.read(locallySettledStopsProvider).keys, ['b']);
    });

    test('acotado a maxEntries (descarta las más viejas)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(locallySettledStopsProvider.notifier);
      for (var i = 0; i < LocallySettledStops.maxEntries + 5; i++) {
        notifier.settle('s$i', DriverRouteStopStatus.completed);
      }
      final state = container.read(locallySettledStopsProvider);
      expect(state, hasLength(LocallySettledStops.maxEntries));
      expect(state.containsKey('s0'), isFalse);
      expect(
        state.containsKey('s${LocallySettledStops.maxEntries + 4}'),
        isTrue,
      );
    });

    testWidgets('la entrega en curso avanza sin esperar al backend', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        overrides: [
          ...gateBase(route: _twoStops()),
          shipmentDetailProvider.overrideWith(
            (ref, id) async => throw const ApiException(status: 0, title: 'x'),
          ),
          deliveryStateProvider.overrideWith(
            (ref, id) async => buildDelivery(shipmentId: id),
          ),
        ],
        child: const ActiveDeliveryScreen(),
        tall: true,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ActiveDeliveryScreen)),
      );
      final sheet = tester.widget<DeliverySheet>(find.byType(DeliverySheet));
      expect(sheet.stop.id, 'a');

      container
          .read(locallySettledStopsProvider.notifier)
          .settle('a', DriverRouteStopStatus.completed);
      await tester.pump();

      expect(
        tester.widget<DeliverySheet>(find.byType(DeliverySheet)).stop.id,
        'b',
      );
    });

    testWidgets('la lista muestra la parada resuelta con su estado', (
      tester,
    ) async {
      await pumpScoped(
        tester,
        overrides: [
          locallySettledStopsProvider.overrideWith(
            () => _SeededSettled({'a': DriverRouteStopStatus.failed}),
          ),
        ],
        child: Scaffold(body: RouteList(route: _twoStops())),
      );

      expect(find.text('Fallida'), findsOneWidget);
    });
  });

  group('detalle del envío solo si falta algo', () {
    test('stopNeedsShipmentDetail', () {
      final full = buildStop(
        customerPhone: '+591 7',
        address: 'Calle 1',
        items: const [Items3(sku: 'S', name: 'N', quantity: 1)],
      );
      expect(stopNeedsShipmentDetail(full), isFalse);
      expect(stopNeedsShipmentDetail(buildStop(address: 'x')), isTrue);
    });

    testWidgets('parada completa: no pide GET /shipments/{id}', (tester) async {
      var detailCalls = 0;
      final stop = buildStop(
        id: 'a',
        shipmentId: 'ship-a',
        customerPhone: '+591 7',
        address: 'Calle 1',
        items: const [Items3(sku: 'S', name: 'Producto', quantity: 1)],
      );
      await pumpScoped(
        tester,
        overrides: [
          ...gateBase(route: buildRoute(stops: [stop])),
          shipmentDetailProvider.overrideWith((ref, id) {
            detailCalls++;
            throw const ApiException(status: 0, title: 'x');
          }),
          deliveryStateProvider.overrideWith(
            (ref, id) async => buildDelivery(shipmentId: id),
          ),
        ],
        child: const ActiveDeliveryScreen(),
        tall: true,
      );

      expect(find.text('+591 7'), findsOneWidget);
      expect(detailCalls, 0);
    });
  });

  group('plausibleDriverFix', () {
    final route = buildRoute(stops: [buildStop(lat: -17.78, lng: -63.18)]);

    test('cerca de la ruta vale; en otro continente se descarta', () {
      const near = GpsFix(lat: -17.9, lng: -63.5);
      const far = GpsFix(lat: 37.4, lng: -122.08); // emulador (California)
      const edge = GpsFix(lat: -17.78, lng: -64.0); // ~87 km
      expect(plausibleDriverFix(route, near), near);
      expect(plausibleDriverFix(route, far), isNull);
      expect(plausibleDriverFix(route, edge), edge);
      expect(
        plausibleDriverFix(route, const GpsFix(lat: -17.78, lng: -65.5)),
        isNull,
      );
    });

    test('ruta sin puntos acepta cualquier fix', () {
      const fix = GpsFix(lat: 1, lng: 1);
      expect(plausibleDriverFix(buildRoute(stops: const []), fix), fix);
    });
  });

  group('carga del camión', () {
    test('effectiveScanCount suma lo local sin duplicar', () {
      final delivery = buildDelivery(
        scans: [
          ScanEvent(
            id: 'e1',
            deliveryId: 'del-1',
            type: ScanType.load,
            unitId: 'u1',
            lat: 0,
            lng: 0,
            deviceId: 'd',
            userId: 'u',
            occurredAt: DateTime(2026),
            idempotencyKey: 'k',
          ),
        ],
      );
      expect(effectiveScanCount(delivery, null), 1);
      expect(effectiveScanCount(delivery, {'u1', 'u2'}), 2);
    });

    testWidgets('al volver de escanear el conteo está al día y se refresca', (
      tester,
    ) async {
      var listCalls = 0;
      await pumpScoped(
        tester,
        overrides: [
          ...gateBase(),
          vehicleDeliveriesProvider.overrideWith((ref) async {
            listCalls++;
            return [buildDelivery(shipmentId: 'ship-1')];
          }),
          continuousScannerProvider.overrideWithValue(
            FakeContinuousScanner.single([validLabelQr()]).call,
          ),
          driverShipmentUnitsProvider.overrideWith(
            (ref, id) async => {vectorUnitId},
          ),
          labelScannerProvider.overrideWithValue(vectorLabelScanner()),
          offlineQueueProvider.overrideWithValue(
            FakeOfflineQueue(SubmitOutcome.queued),
          ),
        ],
        child: const LoadScanScreen(),
      );
      expect(find.text('0 escaneo(s)'), findsOneWidget);
      expect(listCalls, 1);

      await tester.tap(find.text('Envío ship-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escanear bulto para cargar'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Sin señal (encolado): el bulto ya cuenta; y la lista se volvió a pedir.
      expect(find.text('1 escaneo(s)'), findsOneWidget);
      expect(listCalls, 2);
    });
  });
}

class _SeededSettled extends LocallySettledStops {
  _SeededSettled(this.seed);

  final Map<String, DriverRouteStopStatus> seed;

  @override
  Map<String, DriverRouteStopStatus> build() => seed;
}
