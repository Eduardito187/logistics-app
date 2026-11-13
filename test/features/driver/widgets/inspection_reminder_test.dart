import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/presentation/controllers/inspection_history_controller.dart';
import 'package:logistics_app/features/driver/presentation/widgets/daily_inspection_reminder.dart';

// Recordatorio de la inspección diaria: se muestra si HOY falta; se oculta si ya
// se hizo hoy o si no se pudo leer el historial (complementario, sin error).

PreTripChecklist _checklist(DateTime performedOn) =>
    PreTripChecklist(performedOn: performedOn, passed: true);

PreTripChecklist _routeChecklist(String routeId, DateTime performedOn) =>
    PreTripChecklist(routeId: routeId, performedOn: performedOn, passed: true);

void main() {
  group('inspectionForCurrentRoute (gate por ruta con auto-upgrade)', () {
    final now = DateTime(2026, 11, 11, 15, 0);

    test('sin route_id en ningún item => modo DIARIO (hecho hoy cuenta)', () {
      expect(perRouteChecklistMode([_checklist(now)]), isFalse);
      // En modo diario, una inspección de hoy cumple para cualquier ruta.
      expect(
        inspectionForCurrentRoute([_checklist(now)], 'route-x', now),
        isNotNull,
      );
    });

    test('modo por RUTA: cumple solo el checklist de ESA ruta', () {
      final items = [_routeChecklist('route-1', now)];
      expect(perRouteChecklistMode(items), isTrue);
      expect(inspectionForCurrentRoute(items, 'route-1', now), isNotNull);
      // Otra ruta (segunda salida) aún NO tiene inspección, aunque sea el mismo
      // día: debe pedir el formulario.
      expect(inspectionForCurrentRoute(items, 'route-2', now), isNull);
    });

    test('modo por ruta sin ruta en curso => null (no se puede ligar)', () {
      final items = [_routeChecklist('route-1', now)];
      expect(inspectionForCurrentRoute(items, null, now), isNull);
    });
  });

  group('inspectionDoneToday', () {
    final now = DateTime(2026, 11, 11, 15, 0);

    test('inspección de hoy => true', () {
      expect(
        inspectionDoneToday([_checklist(DateTime(2026, 11, 11, 7))], now),
        isTrue,
      );
    });

    test('solo inspección de ayer => false', () {
      expect(
        inspectionDoneToday([_checklist(DateTime(2026, 11, 10, 7))], now),
        isFalse,
      );
    });

    test('lista vacía => false', () {
      expect(inspectionDoneToday(const [], now), isFalse);
    });

    test('performedOn null => no cuenta', () {
      expect(
        inspectionDoneToday([const PreTripChecklist(passed: true)], now),
        isFalse,
      );
    });

    test('alguna de hoy entre varias de otros días => true', () {
      expect(
        inspectionDoneToday([
          _checklist(DateTime(2026, 11, 9)),
          _checklist(DateTime(2026, 11, 11, 6)),
          _checklist(DateTime(2026, 11, 8)),
        ], now),
        isTrue,
      );
    });
  });

  Future<void> pumpReminder(
    WidgetTester tester, {
    required AsyncValue<List<PreTripChecklist>> state,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inspectionHistoryProvider('veh-1').overrideWith(
            (ref) => switch (state) {
              AsyncData(:final value) => value,
              AsyncError(:final error) => throw error,
              _ => Future<List<PreTripChecklist>>.delayed(
                const Duration(seconds: 1),
                () => const [],
              ),
            },
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DailyInspectionReminder(vehicleId: 'veh-1', onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hoy SIN inspección => muestra el recordatorio', (tester) async {
    await pumpReminder(
      tester,
      state: AsyncData([_checklist(DateTime(2020, 1, 1))]), // vieja: falta hoy
    );
    expect(find.text('Revisá el camión hoy'), findsOneWidget);
  });

  testWidgets('inspección de hoy => no muestra nada', (tester) async {
    await pumpReminder(tester, state: AsyncData([_checklist(DateTime.now())]));
    expect(find.text('Revisá el camión hoy'), findsNothing);
  });

  testWidgets('error al leer => no muestra nada (complementario)', (
    tester,
  ) async {
    await pumpReminder(
      tester,
      state: AsyncError(Exception('x'), StackTrace.empty),
    );
    expect(find.text('Revisá el camión hoy'), findsNothing);
  });
}
