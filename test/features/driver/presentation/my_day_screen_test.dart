import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/widgets/stat_tile.dart';
import 'package:logistics_app/features/driver/domain/entities/my_day_stats.dart';
import 'package:logistics_app/features/driver/presentation/my_day_screen.dart';

import '../../../support/screen_sizes.dart';
import '../support/driver_test_support.dart';

// "Mi día" del chofer: métricas calculadas de la ruta del día (totales,
// entregadas, fallidas, pendientes, primera/última hora y promedio por
// parada). Sin datos de conexión ni sincronización (offline invisible).

DriverRoute _route() => buildRoute(
  totalStops: 5,
  completedStops: 3,
  stopsRemaining: 2,
  stops: [
    buildStop(
      id: 's1',
      sequence: 1,
      status: DriverRouteStopStatus.completed,
      settledAt: DateTime(2026, 10, 15, 9, 0),
    ),
    buildStop(
      id: 's2',
      sequence: 2,
      status: DriverRouteStopStatus.failed,
      settledAt: DateTime(2026, 10, 15, 9, 40),
    ),
    buildStop(
      id: 's3',
      sequence: 3,
      status: DriverRouteStopStatus.completed,
      settledAt: DateTime(2026, 10, 15, 10, 20),
    ),
    buildStop(id: 's4', sequence: 4),
    buildStop(id: 's5', sequence: 5),
  ],
);

Future<void> _pump(WidgetTester tester, DriverRoute route) => pumpScoped(
  tester,
  overrides: gateBase(route: route),
  child: const MyDayScreen(),
  tall: true,
);

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('MyDayStats.fromRoute', () {
    test('cuenta por estado y calcula horarios y promedio', () {
      final s = MyDayStats.fromRoute(_route());
      expect(s.total, 5);
      expect(s.delivered, 2);
      expect(s.failed, 1);
      expect(s.pending, 2);
      expect(s.attended, 3);
      expect(s.progress, closeTo(0.6, 1e-9));
      expect(s.firstSettledAt, DateTime(2026, 10, 15, 9, 0));
      expect(s.lastSettledAt, DateTime(2026, 10, 15, 10, 20));
      // 80 min entre el primer y el último cierre / 2 intervalos.
      expect(s.averagePerStop, const Duration(minutes: 40));
    });

    test('sin cierres no hay horarios ni promedio', () {
      final s = MyDayStats.fromRoute(
        buildRoute(
          stops: [
            buildStop(),
            buildStop(id: 'b'),
          ],
        ),
      );
      expect(s.pending, 2);
      expect(s.firstSettledAt, isNull);
      expect(s.averagePerStop, isNull);
    });

    test('con un solo cierre hay hora pero no promedio', () {
      final s = MyDayStats.fromRoute(
        buildRoute(
          stops: [
            buildStop(
              status: DriverRouteStopStatus.completed,
              settledAt: DateTime(2026, 10, 15, 11),
            ),
          ],
        ),
      );
      expect(s.firstSettledAt, s.lastSettledAt);
      expect(s.averagePerStop, isNull);
    });

    test('sin paradas listadas usa totalStops', () {
      final s = MyDayStats.fromRoute(
        buildRoute(totalStops: 4, completedStops: 0, stops: const []),
      );
      expect(s.total, 4);
      expect(s.pending, 4);
      expect(s.progress, 0);
    });
  });

  test('formatAveragePerStop', () {
    expect(formatAveragePerStop(null), '—');
    expect(formatAveragePerStop(const Duration(minutes: 18)), '18 min');
    expect(formatAveragePerStop(const Duration(minutes: 75)), '1 h 15 min');
  });

  testWidgets('muestra las métricas del día en mosaicos', (tester) async {
    await _pump(tester, _route());

    expect(find.text('Mi día'), findsOneWidget);
    expect(find.text('3 de 5 paradas atendidas'), findsOneWidget);
    expect(find.byType(StatTile), findsNWidgets(7));

    String valueOf(String label) => tester
        .widget<StatTile>(
          find.ancestor(of: find.text(label), matching: find.byType(StatTile)),
        )
        .value;
    expect(valueOf('Totales'), '5');
    expect(valueOf('Entregadas'), '2');
    expect(valueOf('No entregadas'), '1');
    expect(valueOf('Pendientes'), '2');
    expect(valueOf('Primera entrega'), '9:00');
    expect(valueOf('Última entrega'), '10:20');
    expect(valueOf('Promedio por parada'), '40 min');
    expect(find.text('Ver ruta del día'), findsOneWidget);
    // Offline invisible: nada de conexión ni pendientes de sincronizar.
    expect(find.textContaining('conexión'), findsNothing);
    expect(find.textContaining('sincroniz'), findsNothing);
  });

  testWidgets('sin paradas: lo dice y deja los tiempos en "—"', (tester) async {
    await _pump(tester, buildEmptyRoute());

    expect(find.text('Todavía no tenés paradas para hoy.'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
  });

  testOnScreens('sin desbordes con letra grande', (tester, screen) async {
    await pumpScoped(
      tester,
      overrides: gateBase(route: _route()),
      child: withTextScale(const MyDayScreen()),
    );

    expect(find.text('Mi día'), findsOneWidget);
    expect(find.text('Totales'), findsOneWidget);
  });
}
