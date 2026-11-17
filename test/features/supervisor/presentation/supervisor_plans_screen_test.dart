import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plans_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plan_card.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plans_date_bar.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plans_filter_bar.dart';

import '../../../support/screen_sizes.dart';
import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// SupervisorPlansScreen: barra de fecha + fila de filtros + lista de planes del
// día (datos, vacío, error, filtro por estado y búsqueda).

Future<void> _pump(
  WidgetTester tester,
  FakeSupervisorRepository repo, {
  Widget Function(Widget child)? wrap,
}) async {
  const screen = SupervisorPlansScreen();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: wrap == null ? screen : wrap(const SupervisorPlansScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Dos planes con estado, placa y chofer distintos para probar los filtros.
FakeSupervisorRepository _twoPlans() =>
    FakeSupervisorRepository()
      ..plansByDate = [
        plan(
          id: 'p1',
          vehicleId: 'CAM-1',
          status: PlanStatus.published,
          plate: '1234ABC',
          driverName: 'Juan Pérez',
        ),
        plan(
          id: 'p2',
          vehicleId: 'CAM-2',
          status: PlanStatus.draft,
          plate: '5678XYZ',
          driverName: 'María López',
        ),
      ];

void main() {
  testWidgets('con datos muestra la barra de fecha y las tarjetas de plan', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..plansByDate = [
        plan(id: 'p1', vehicleId: 'CAM-1'),
        plan(id: 'p2', vehicleId: 'CAM-2'),
      ];
    await _pump(tester, repo);

    expect(find.text('Rutas en curso'), findsOneWidget); // título
    expect(find.byType(PlansDateBar), findsOneWidget);
    // La fila de filtros aparece cuando hay planes ese día.
    expect(find.byType(PlansFilterBar), findsOneWidget);
    expect(find.byType(PlanCard), findsNWidgets(2));
    expect(find.text('Camión CAM-1'), findsOneWidget);
    expect(find.text('Camión CAM-2'), findsOneWidget);
  });

  testWidgets('sin planes muestra el estado vacío y oculta los filtros', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()..plansByDate = const [];
    await _pump(tester, repo);

    expect(find.text('Sin planes para este día'), findsOneWidget);
    // La barra de fecha sigue visible para poder cambiar de día.
    expect(find.byType(PlansDateBar), findsOneWidget);
    // Sin planes no hay nada que filtrar: la fila de filtros no se muestra.
    expect(find.byType(PlansFilterBar), findsNothing);
  });

  testWidgets('en error muestra el estado de error con reintento', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..plansError = const ApiException(status: 500, title: 'x');
    await _pump(tester, repo);

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('el SELECT de estado filtra la lista', (tester) async {
    await _pump(tester, _twoPlans());
    expect(find.byType(PlanCard), findsNWidgets(2));

    // Abrir el SELECT y elegir "Borrador" (solo el plan p2 lo es).
    await tester.tap(find.byKey(const Key('plans-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrador').last);
    await tester.pumpAndSettle();

    expect(find.byType(PlanCard), findsOneWidget);
    expect(find.text('Camión CAM-2'), findsOneWidget);
    expect(find.text('Camión CAM-1'), findsNothing);
  });

  testWidgets('el buscador filtra por placa', (tester) async {
    await _pump(tester, _twoPlans());

    await tester.enterText(find.byKey(const Key('plans-search-field')), '1234');
    await tester.pumpAndSettle();

    expect(find.byType(PlanCard), findsOneWidget);
    expect(find.text('Camión CAM-1'), findsOneWidget);
  });

  testWidgets('el buscador filtra por chofer sin tildes ni mayúsculas', (
    tester,
  ) async {
    await _pump(tester, _twoPlans());

    // "lopez" (sin tilde, minúsculas) debe encontrar a "María López".
    await tester.enterText(
      find.byKey(const Key('plans-search-field')),
      'lopez',
    );
    await tester.pumpAndSettle();

    expect(find.byType(PlanCard), findsOneWidget);
    expect(find.text('Camión CAM-2'), findsOneWidget);
  });

  testWidgets(
    'con filtro que no coincide muestra el vacío propio y se puede limpiar',
    (tester) async {
      await _pump(tester, _twoPlans());

      await tester.enterText(
        find.byKey(const Key('plans-search-field')),
        'zzz',
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlanCard), findsNothing);
      expect(find.text('Ningún plan coincide con el filtro'), findsOneWidget);
      // Es el vacío del filtro, no el del día sin planes.
      expect(find.text('Sin planes para este día'), findsNothing);

      // "Limpiar filtro" devuelve las dos tarjetas y vacía la caja.
      await tester.tap(find.byKey(const Key('plans-clear-filter')));
      await tester.pumpAndSettle();

      expect(find.byType(PlanCard), findsNWidgets(2));
      final field = tester.widget<TextField>(
        find.byKey(const Key('plans-search-field')),
      );
      expect(field.controller?.text, isEmpty);
    },
  );

  testOnScreens('la fila de filtros entra sin desbordar', (
    tester,
    screen,
  ) async {
    await _pump(tester, _twoPlans(), wrap: (child) => withTextScale(child));

    // Si algo se desborda en cualquier tamaño, el framework falla solo.
    expect(find.byType(PlansFilterBar), findsOneWidget);
    expect(find.byKey(const Key('plans-status-filter')), findsOneWidget);
    expect(find.byKey(const Key('plans-search-field')), findsOneWidget);
  });
}
