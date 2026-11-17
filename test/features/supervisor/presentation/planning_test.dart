import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/features/lookup/data/order_lookup_data_source.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/planning_controllers.dart';
import 'package:logistics_app/features/supervisor/presentation/planning_actions_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plan_detail_screen.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// Planificación desde la app: el planificador y el administrador planifican el
// día, ordenan paradas, agregan pedidos y publican. El supervisor solo mira.

AutoPlanRun _run(AutoPlanRunStatus status, {int unassigned = 0}) => AutoPlanRun(
  id: 'run-1',
  planDate: DateTime(2026, 11, 15),
  strategy: AutoPlanRunStrategy.optimization,
  status: status,
  requestedAt: DateTime(2026, 11, 15, 8),
  trucksPlanned: 3,
  stopsPlanned: 12,
  unassignedCount: unassigned,
);

class _Lookup implements OrderLookupDataSource {
  _Lookup(this.items);

  final List<OrderLookupItem> items;

  @override
  Future<List<OrderLookupItem>> search(String query) async => items;
}

OrderLookupItem _order(String id, String code) => OrderLookupItem.fromJson({
  'id': id,
  'source': 'SAP',
  'external_id': code,
  'customer_name': 'Cliente',
  'address_text': 'Calle 1',
  'address_confidence_score': 70,
  'address_confidence_level': 'HIGH',
  'status': 'PLANNED',
  'lines': <Object?>[],
  'tracking': {'stage': 'planned'},
  'can_process': true,
});

Future<void> _pump(
  WidgetTester tester,
  FakeSupervisorRepository repo,
  Widget screen, {
  bool canPlan = true,
  List<OrderLookupItem> orders = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supervisorRepositoryProvider.overrideWithValue(repo),
        canPlanProvider.overrideWithValue(canPlan),
        orderLookupDataSourceProvider.overrideWithValue(_Lookup(orders)),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

final _draft = plan(
  id: 'p1',
  vehicleId: 'CAM-1',
  status: PlanStatus.proposed,
  stops: [
    plannedStop(sequence: 1, loadOrder: 2, shipmentId: 'S1'),
    plannedStop(sequence: 2, loadOrder: 1, shipmentId: 'S2'),
  ],
);

void main() {
  test('planifican el planificador y el administrador; el supervisor no', () {
    expect(UserRole.planner.canPlan, isTrue);
    expect(UserRole.admin.canPlan, isTrue);
    expect(UserRole.supervisor.canPlan, isFalse);
    expect(UserRole.planner.backendKey, 'planificador');
  });

  group('día', () {
    testWidgets('planificar el día encola la corrida y muestra el resultado', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()
        ..runAfterGenerate = _run(AutoPlanRunStatus.completed, unassigned: 2);
      await _pump(tester, repo, const PlanningActionsScreen());

      expect(find.text('Este día todavía no se planificó.'), findsOneWidget);

      await tester.tap(find.text('Planificar el día'));
      await tester.pumpAndSettle();

      expect(repo.generatedDays, hasLength(1));
      expect(find.text('Planificado: 3 camiones, 12 paradas.'), findsOneWidget);
      expect(find.text('2 pedidos quedaron sin camión.'), findsOneWidget);
    });

    testWidgets('mientras corre, no deja volver a planificar', (tester) async {
      final repo = FakeSupervisorRepository()
        ..run = _run(AutoPlanRunStatus.processing);
      await tester.runAsync(() async {});
      tester.view.physicalSize = const Size(1200, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supervisorRepositoryProvider.overrideWithValue(repo),
            canPlanProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(home: PlanningActionsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Planificando…'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Planificando…'),
          matching: find.bySubtype<FilledButton>(),
        ),
      );
      expect(button.onPressed, isNull);

      // Termina: la próxima consulta lo ve completo y deja de consultar.
      repo.run = _run(AutoPlanRunStatus.completed);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(find.text('Planificado: 3 camiones, 12 paradas.'), findsOneWidget);
    });

    testWidgets('publicar todos: solo los planes sin publicar y con paradas', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()
        ..plansByDate = [
          _draft,
          plan(id: 'p2', vehicleId: 'CAM-2'),
          plan(id: 'p3', vehicleId: 'CAM-3', status: PlanStatus.draft),
        ];
      await _pump(tester, repo, const PlanningActionsScreen());

      await tester.tap(find.text('Publicar 1 plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
      await tester.pumpAndSettle();

      expect(repo.publishedIds, ['p1']);
      expect(find.text('Plan publicado.'), findsOneWidget);
    });

    testWidgets('quien solo mira no ve acciones de planificación', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()..plansByDate = [_draft];
      await _pump(tester, repo, const PlanningActionsScreen(), canPlan: false);

      // El que solo mira no entra a planificar: ve el aviso de solo lectura.
      expect(find.text('Solo lectura'), findsOneWidget);
      expect(find.text('Planificar el día'), findsNothing);
      expect(find.text('Publicar 1 plan'), findsNothing);
    });
  });

  group('plan', () {
    const detail = SupervisorPlanDetailScreen(planId: 'p1');

    FakeSupervisorRepository repoWith(Plan value) => FakeSupervisorRepository()
      ..planValue = value
      ..planEtaValue = planEtaData(planId: 'p1', stops: const []);

    testWidgets('ordenar paradas y guardar el orden', (tester) async {
      final repo = repoWith(_draft);
      await _pump(tester, repo, detail);

      expect(find.text('Guardar orden'), findsNothing);
      await tester.tap(find.text('Bajar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar orden'));
      await tester.pumpAndSettle();

      expect(repo.reordered.single.planId, 'p1');
      expect(repo.reordered.single.order, ['S2', 'S1']);
      expect(find.text('Orden guardado.'), findsOneWidget);
    });

    testWidgets('publicar el plan pide confirmación', (tester) async {
      final repo = repoWith(_draft);
      await _pump(tester, repo, detail);

      await tester.tap(find.text('Publicar plan'));
      await tester.pumpAndSettle();
      expect(repo.publishedIds, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
      await tester.pumpAndSettle();

      expect(repo.publishedIds, ['p1']);
    });

    testWidgets('agregar un pedido por su código', (tester) async {
      final repo = repoWith(_draft);
      await _pump(
        tester,
        repo,
        detail,
        orders: [_order('ship-9', 'SO-900009')],
      );

      await tester.tap(find.text('Agregar pedido'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'so-900009');
      await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(repo.assigned.single, (planId: 'p1', shipmentId: 'ship-9'));
      expect(find.text('Pedido agregado al camión.'), findsOneWidget);
    });

    testWidgets('código que no existe: avisa y no agrega', (tester) async {
      final repo = repoWith(_draft);
      await _pump(tester, repo, detail);

      await tester.tap(find.text('Agregar pedido'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'NADA');
      await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
      await tester.pumpAndSettle();

      expect(repo.assigned, isEmpty);
      expect(find.text('Pedido no encontrado.'), findsOneWidget);
    });

    testWidgets('un plan publicado ya no se edita', (tester) async {
      final repo = repoWith(
        plan(
          id: 'p1',
          vehicleId: 'CAM-1',
          stops: [plannedStop(sequence: 1, loadOrder: 1, shipmentId: 'S1')],
        ),
      );
      await _pump(tester, repo, detail);

      expect(find.text('Publicar plan'), findsNothing);
      expect(find.text('Agregar pedido'), findsNothing);
      expect(find.text('Subir'), findsNothing);
    });

    testWidgets('quien solo mira ve el plan sin acciones', (tester) async {
      final repo = repoWith(_draft);
      await _pump(tester, repo, detail, canPlan: false);

      expect(find.text('Parada 1'), findsWidgets);
      expect(find.text('Publicar plan'), findsNothing);
      expect(find.text('Bajar'), findsNothing);
    });
  });
}
