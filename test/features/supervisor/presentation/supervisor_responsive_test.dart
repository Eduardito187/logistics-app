import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/alert_severity.dart';
import 'package:logistics_app/core/api/models/alert_type.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/api/models/vehicle_live.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/widgets/stat_tile.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_alerts_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_dashboard_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_fleet_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plan_detail_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plans_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/alert_card.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/eta_section.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/fleet_map.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plan_card.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/stop_tile.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/vehicle_sheet.dart';

import '../../../support/screen_sizes.dart';
import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// Layout de las pantallas del supervisor en los 4 tamaños de referencia
// (teléfono chico 320x568 → tablet horizontal 1280x800) con letra a 1.3x y el
// tema real de la app. Un desborde hace fallar el test solo. Además se cubre
// que el mapa de flota no reagrupa los marcadores si la flota no cambió.

Widget _app(FakeSupervisorRepository repo, Widget home) => ProviderScope(
  overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(theme: AppTheme.light(), home: withTextScale(home)),
);

FakeSupervisorRepository _dashboardRepo() => FakeSupervisorRepository()
  ..shipments = [
    for (var i = 0; i < 40; i++)
      shipment(
        ShipmentStatus.values[i % (ShipmentStatus.values.length - 1)],
        id: 's$i',
      ),
  ]
  ..plansByDate = [plan(id: 'p1'), plan(id: 'p2')]
  ..alerts = [alert(id: 'a1'), alert(id: 'a2')];

List<VehicleLive> _fleet() => [
  vehicleLive(vehicleId: 'v1', speedKph: 40),
  vehicleLive(vehicleId: 'v2', lat: -16.51, lng: -68.16, moving: false),
];

void main() {
  testOnScreens('tablero: mosaicos sin desborde, 2 por fila en teléfono y 3 '
      'en tablet', (tester, screen) async {
    await tester.pumpWidget(
      _app(_dashboardRepo(), const SupervisorDashboardScreen()),
    );
    await tester.pumpAndSettle();

    final tiles = find.byType(StatTile);
    expect(tiles, findsNWidgets(6));
    final first = tester.getRect(tiles.at(0));
    final second = tester.getRect(tiles.at(1));
    final third = tester.getRect(tiles.at(2));
    expect(second.top, first.top);
    final phone = screen == TestScreen.smallPhone || screen == TestScreen.phone;
    if (phone) {
      expect(third.top, greaterThan(first.top));
    } else {
      expect(third.top, first.top);
    }
    // En tablet grande el tablero no se estira de borde a borde.
    final rowWidth = (phone ? second.right : third.right) - first.left;
    expect(rowWidth, lessThanOrEqualTo(1040));
  });

  testOnScreens('planes: tarjetas sin desborde y en columnas en tablet', (
    tester,
    screen,
  ) async {
    final repo = FakeSupervisorRepository()
      ..plansByDate = [
        for (var i = 0; i < 9; i++)
          plan(
            id: 'p$i',
            vehicleId: 'CAMION-LARGO-$i',
            status: PlanStatus.proposed,
            stops: [
              plannedStop(
                sequence: 1,
                loadOrder: 1,
                etaAt: DateTime(2026, 3, 9, 12, 45),
              ),
            ],
          ),
      ];
    await tester.pumpWidget(_app(repo, const SupervisorPlansScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cambiar fecha'), findsOneWidget);
    final cards = find.byType(PlanCard);
    expect(cards, findsWidgets);
    if (screen.size.width >= 600) {
      // En tablet la segunda tarjeta va al lado de la primera.
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));
      expect(second.top, first.top);
      expect(second.left, greaterThan(first.right));
    }
  });

  testOnScreens('alertas: filtros y tarjetas sin desborde', (
    tester,
    screen,
  ) async {
    final repo = FakeSupervisorRepository()
      ..alerts = [
        for (var i = 0; i < 8; i++)
          alert(
            id: 'a$i',
            vehicleId: 'CAMION-$i',
            type: AlertType.afterHoursMovement,
            severity: AlertSeverity.critical,
            detail: {'zona': 'Norte', 'velocidad': 92},
            acknowledgedAt: i.isEven ? DateTime(2026, 3, 9, 9) : null,
          ),
      ];
    await tester.pumpWidget(_app(repo, const SupervisorAlertsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sin reconocer'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.byType(AlertCard), findsWidgets);
    // Lista perezosa: en teléfono no se construyen las 8 tarjetas.
    if (screen == TestScreen.smallPhone) {
      expect(
        tester.widgetList(find.byType(AlertCard)).length,
        lessThan(repo.alerts.length),
      );
    }
  });

  testOnScreens(
    'detalle del plan: en tablet grande ETA y paradas lado a lado',
    (tester, screen) async {
      final repo = FakeSupervisorRepository()
        ..planValue = plan(
          id: 'p1',
          vehicleId: 'CAMION-CON-PATENTE-LARGA',
          stops: [
            for (var i = 1; i <= 6; i++)
              plannedStop(
                id: 'st$i',
                sequence: i,
                loadOrder: 7 - i,
                shipmentId: 'ENVIO-0000$i',
                lane: 'CARRIL-$i',
                etaMinutes: 15 * i,
                etaAt: DateTime(2026, 3, 9, 9 + i),
              ),
          ],
        )
        ..planEtaValue = planEtaData(
          stops: [
            for (var i = 1; i <= 6; i++)
              stopEta(
                sequence: i,
                shipmentId: 'ENVIO-0000$i',
                etaAt: DateTime(2026, 3, 9, 9 + i),
              ),
          ],
        );
      await tester.pumpWidget(
        _app(repo, const SupervisorPlanDetailScreen(planId: 'p1')),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      // En teléfono la secuencia queda debajo del ETA: se scrollea hasta su
      // título y un poco más para que se construya la primera parada.
      await tester.scrollUntilVisible(
        find.text('Secuencia de paradas'),
        200,
        scrollable: scrollable,
      );
      await tester.drag(scrollable, const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(find.byType(StopTile), findsWidgets);
      if (screen == TestScreen.tabletLandscape) {
        final eta = tester.getRect(find.byType(EtaSection));
        final stop = tester.getRect(find.byType(StopTile).first);
        expect(stop.left, greaterThan(eta.right));
      }
    },
  );

  testOnScreens('flota en vivo: mapa y hoja del camión sin desborde', (
    tester,
    screen,
  ) async {
    final repo = FakeSupervisorRepository()
      ..fleet = _fleet()
      ..vehicleSummaryValue = vehicleSummary(vehicleId: 'v1');
    await tester.pumpWidget(_app(repo, const SupervisorFleetScreen()));
    // Sin pumpAndSettle: tiles y clustering programan trabajo continuo.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FleetMap), findsOneWidget);

    // La hoja del camión, abierta sobre el mapa, tampoco desborda.
    final context = tester.element(find.byType(FleetMap));
    unawaited(VehicleSheet.show(context, _fleet().first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Camión v1'), findsOneWidget);
    expect(find.text('Resumen del día'), findsOneWidget);
  });

  group('FleetMap (rendimiento)', () {
    MarkerClusterLayerOptions options(WidgetTester tester) => tester
        .widget<MarkerClusterLayerWidget>(find.byType(MarkerClusterLayerWidget))
        .options;

    Future<void> pumpMap(WidgetTester tester, List<VehicleLive> fleet) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FleetMap(vehicles: fleet)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('una flota igual (lista nueva) no recrea los marcadores', (
      tester,
    ) async {
      await pumpMap(tester, _fleet());
      final before = options(tester).markers;
      await pumpMap(tester, _fleet());
      expect(identical(options(tester).markers, before), isTrue);
    });

    testWidgets('si un camión se movió, los marcadores se recalculan', (
      tester,
    ) async {
      await pumpMap(tester, _fleet());
      final before = options(tester).markers;
      final moved = _fleet()
        ..[0] = vehicleLive(vehicleId: 'v1', lat: -16.6, speedKph: 40);
      await pumpMap(tester, moved);
      expect(identical(options(tester).markers, before), isFalse);
      expect(options(tester).markers, hasLength(2));
    });

    test('sameFleetPositions compara id, posición, estado y velocidad', () {
      expect(sameFleetPositions(_fleet(), _fleet()), isTrue);
      expect(sameFleetPositions(_fleet(), _fleet().sublist(1)), isFalse);
      final stopped = _fleet()..[0] = vehicleLive(vehicleId: 'v1');
      expect(sameFleetPositions(_fleet(), stopped), isFalse);
      final faster = _fleet()..[0] = vehicleLive(vehicleId: 'v1', speedKph: 80);
      expect(sameFleetPositions(_fleet(), faster), isFalse);
    });
  });
}
