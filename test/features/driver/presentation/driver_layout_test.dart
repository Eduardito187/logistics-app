import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/widgets/section_card.dart';
import 'package:logistics_app/features/driver/domain/entities/due_maintenance_item.dart';
import 'package:logistics_app/features/driver/presentation/checklist_screen.dart';
import 'package:logistics_app/features/driver/presentation/controllers/driver_controllers.dart';
import 'package:logistics_app/features/driver/presentation/controllers/fleet_ops_controllers.dart';
import 'package:logistics_app/features/driver/presentation/driver_route_screen.dart';
import 'package:logistics_app/features/driver/presentation/failed_delivery_screen.dart';
import 'package:logistics_app/features/driver/presentation/fuel_screen.dart';
import 'package:logistics_app/features/driver/presentation/incident_screen.dart';
import 'package:logistics_app/features/driver/presentation/live_gps_screen.dart';
import 'package:logistics_app/features/driver/presentation/load_scan_screen.dart';
import 'package:logistics_app/features/driver/presentation/maintenance_due_screen.dart';
import 'package:logistics_app/features/driver/presentation/odometer_screen.dart';
import 'package:logistics_app/features/driver/presentation/pod_screen.dart';
import 'package:logistics_app/features/driver/presentation/scan_mode.dart';
import 'package:logistics_app/features/driver/presentation/scan_units_screen.dart';
import 'package:logistics_app/features/driver/presentation/stop_detail_screen.dart';
import 'package:logistics_app/features/driver/presentation/vehicle_summary_screen.dart';
import 'package:logistics_app/features/driver/presentation/widgets/due_card.dart';
import 'package:logistics_app/features/driver/presentation/widgets/stop_card.dart';

import '../../../support/fake_photo_picker.dart';
import '../../../support/screen_sizes.dart';
import '../support/driver_test_support.dart';

// Layout de las pantallas del chofer en los 4 tamaños de referencia (teléfono
// chico 320x568 hasta tablet horizontal 1280x800) con letra del sistema a 1.3x
// (el tope de la app). Un desborde hace fallar el test solo. Además se recorre
// cada lista hasta el final (las listas perezosas solo construyen lo visible) y
// se verifica que en tablets el contenido no se estira de borde a borde.

const _longName =
    'Distribuidora Comercial Santa Cruz de la Sierra S.R.L. Sucursal Norte';
const _longAddress =
    'Av. Cristo Redentor entre 4to y 5to anillo, calle Los Tajibos #1234, '
    'edificio Torre Empresarial, piso 12';

DriverRouteStop _longStop({int sequence = 1, String id = 'stop-1'}) =>
    buildStop(
      id: id,
      sequence: sequence,
      shipmentId: 'ship-$sequence',
      customerName: _longName,
      orderReference: 'PED-0000-0000-0000-$sequence',
      address: _longAddress,
      etaAt: DateTime(2026, 10, 15, 14, 5),
      lat: -17.78,
      lng: -63.18,
    );

/// Monta [child] con letra a 1.3x.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<Object> overrides = const [],
}) => pumpScoped(tester, overrides: overrides, child: withTextScale(child));

/// Recorre la lista vertical principal hasta el final para construir (y
/// maquetar) todos sus ítems.
Future<void> _scrollToEnd(WidgetTester tester) async {
  final scrollable = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  if (scrollable.evaluate().isEmpty) return;
  for (var i = 0; i < 6; i++) {
    await tester.drag(
      scrollable.first,
      const Offset(0, -600),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }
}

/// En pantallas anchas las tarjetas de formulario/lista no superan [maxWidth].
void _expectCappedWidth(
  WidgetTester tester,
  TestScreen screen, {
  double maxWidth = AppBreakpoints.maxContentWidth,
}) {
  if (screen.size.width <= maxWidth) return;
  final cards = find.byType(SectionCard);
  expect(cards, findsWidgets);
  expect(tester.getSize(cards.first).width, lessThanOrEqualTo(maxWidth));
}

void main() {
  setUpAll(() async => initializeDateFormatting('es', null));

  group('ruta del día', () {
    testOnScreens('lista de paradas con textos largos', (tester, screen) async {
      await _pump(
        tester,
        const DriverRouteScreen(),
        overrides: gateBase(
          route: buildRoute(
            totalStops: 6,
            completedStops: 2,
            stopsRemaining: 4,
            stops: [
              for (var i = 1; i <= 6; i++) _longStop(sequence: i, id: 's$i'),
            ],
          ),
        ),
      );
      await tester.tap(find.byTooltip('Ver lista'));
      await tester.pumpAndSettle();

      expect(find.byType(StopCard), findsWidgets);
      // En tablets las tarjetas se reparten en columnas (misma fila).
      final columns = AppBreakpoints.columnsFor(screen.size.width);
      if (columns > 1) {
        final first = tester.getTopLeft(find.byType(StopCard).at(0));
        final second = tester.getTopLeft(find.byType(StopCard).at(1));
        expect(second.dy, first.dy);
        expect(second.dx, greaterThan(first.dx));
      }
      await _scrollToEnd(tester);
    });

    testOnScreens('sin paradas: estado vacío con botón', (
      tester,
      screen,
    ) async {
      await _pump(
        tester,
        const DriverRouteScreen(),
        overrides: gateBase(
          route: buildRoute(
            status: DriverRouteStatus.planned,
            totalStops: 0,
            completedStops: 0,
            stopsRemaining: 0,
            stops: const [],
          ),
        ),
      );
      expect(find.text('Sin paradas'), findsOneWidget);
    });
  });

  testOnScreens('detalle de parada', (tester, screen) async {
    final stop = _longStop();
    await _pump(
      tester,
      StopDetailScreen(stop: stop),
      overrides: [
        deliveryStateProvider(stop.shipmentId).overrideWith(
          (ref) async => buildDelivery(
            shipmentId: stop.shipmentId,
            status: DeliveryStatus.failed,
            podConfirmation: 'CONF-0000-0000-0000-0000-0000',
            failureReason: FailureReason.wrongAddress,
          ),
        ),
      ],
    );
    _expectCappedWidth(tester, screen);
    await _scrollToEnd(tester);
    expect(find.text('Entrega fallida'), findsOneWidget);
  });

  testOnScreens('prueba de entrega (POD) con foto adjunta', (
    tester,
    screen,
  ) async {
    final picker = FakePhotoPicker(['/tmp/pod.jpg']);
    await _pump(
      tester,
      PodScreen(stop: _longStop()),
      overrides: [photoPickerProvider.overrideWithValue(picker.call)],
    );
    _expectCappedWidth(tester, screen, maxWidth: AppBreakpoints.maxFormWidth);
    await tester.scrollUntilVisible(find.text('Tomar foto'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    await _scrollToEnd(tester);
    expect(find.text('Registrar entrega'), findsOneWidget);
  });

  testOnScreens('entrega fallida', (tester, screen) async {
    await _pump(tester, FailedDeliveryScreen(stop: _longStop()));
    _expectCappedWidth(tester, screen, maxWidth: AppBreakpoints.maxFormWidth);
    await _scrollToEnd(tester);
    expect(find.text('Registrar entrega fallida'), findsOneWidget);
  });

  group('escaneo de bultos', () {
    testOnScreens('vacío', (tester, screen) async {
      await _pump(
        tester,
        const ScanUnitsScreen(
          mode: ScanMode.unload,
          shipmentId: 'ship-1',
          nodeId: 'node-1',
          title: 'Descargar parada 12',
        ),
      );
      expect(find.text('Sin bultos'), findsOneWidget);
      expect(find.text('Escanear bulto para descargar'), findsOneWidget);
    });

    testOnScreens('lista de envíos para cargar', (tester, screen) async {
      await _pump(
        tester,
        const LoadScanScreen(),
        overrides: [
          ...gateBase(),
          vehicleDeliveriesProvider.overrideWith(
            (ref) async => [
              for (var i = 0; i < 8; i++)
                buildDelivery(
                  id: 'd$i',
                  shipmentId: '01JB8ZQ4X7K2M9N5P6R7S8T9V$i',
                  status: DeliveryStatus.inTransit,
                ),
            ],
          ),
        ],
      );
      await _scrollToEnd(tester);
    });
  });

  testOnScreens('combustible', (tester, screen) async {
    await _pump(
      tester,
      const FuelScreen(),
      overrides: [
        ...gateBase(),
        currentFuelPriceProvider(
          FuelType.diesel,
        ).overrideWith((ref) async => buildFuelPrice()),
        vehicleRefuelsProvider.overrideWith(
          (ref) async => [for (var i = 0; i < 5; i++) buildRefuel()],
        ),
      ],
    );
    _expectCappedWidth(tester, screen, maxWidth: AppBreakpoints.maxFormWidth);
    await _scrollToEnd(tester);
    expect(find.text('Cargas recientes'), findsOneWidget);
  });

  testOnScreens('odómetro', (tester, screen) async {
    await _pump(
      tester,
      const OdometerScreen(),
      overrides: [
        ...gateBase(),
        vehicleOdometerReadingsProvider.overrideWith(
          (ref) async => [for (var i = 0; i < 5; i++) buildReading()],
        ),
      ],
    );
    _expectCappedWidth(tester, screen, maxWidth: AppBreakpoints.maxFormWidth);
    await _scrollToEnd(tester);
    expect(find.text('Lecturas recientes'), findsOneWidget);
  });

  testOnScreens('resumen del vehículo', (tester, screen) async {
    await _pump(
      tester,
      const VehicleSummaryScreen(),
      overrides: [
        ...gateBase(),
        vehicleCostSummaryProvider.overrideWith(
          (ref) async => buildCostSummary(),
        ),
        vehicleUtilizationProvider.overrideWith(
          (ref) async => <String, Object?>{
            'active_days': 20,
            'kilometers_per_active_day_average': 123.45,
          },
        ),
      ],
    );
    _expectCappedWidth(tester, screen);
    await _scrollToEnd(tester);
  });

  testOnScreens('rastreo del camión', (tester, screen) async {
    await _pump(
      tester,
      const LiveGpsScreen(),
      overrides: gateBase(
        crew: buildMyCrew(
          vehicle: buildVehicle(plate: 'CAMIÓN-1234-SCZ'),
          driver: buildDriver(name: 'Juan Carlos Pérez Mamani de la Fuente'),
        ),
      ),
    );
    await _scrollToEnd(tester);
  });

  testOnScreens('reporte de incidente', (tester, screen) async {
    await _pump(tester, const IncidentScreen(), overrides: gateBase());
    _expectCappedWidth(tester, screen, maxWidth: AppBreakpoints.maxFormWidth);
    await _scrollToEnd(tester);
  });

  testOnScreens('checklist pre-salida', (tester, screen) async {
    await _pump(
      tester,
      const ChecklistScreen(),
      overrides: [
        ...gateBase(),
        driversProvider.overrideWith(
          (ref) async => [buildDriver(name: _longName)],
        ),
      ],
    );
    _expectCappedWidth(tester, screen, maxWidth: AppBreakpoints.maxFormWidth);
    await _scrollToEnd(tester);
  });

  testOnScreens('mantenimiento por vencer', (tester, screen) async {
    await _pump(
      tester,
      const MaintenanceDueScreen(),
      overrides: [
        dueMaintenanceProvider.overrideWith(
          (ref) async => [
            for (var i = 0; i < 6; i++)
              const DueMaintenanceItem(
                overdue: true,
                plate: 'ABC-123',
                serviceKind: MaintenancePlanServiceKind.oilChange,
                remainingDays: -3,
                remainingKm: -1200,
                currentKm: 123456,
                nextDueKm: 122256,
              ),
          ],
        ),
      ],
    );
    expect(find.byType(DueCard), findsWidgets);
    await _scrollToEnd(tester);
  });
}
