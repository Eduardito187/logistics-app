import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/realtime/pusher_socket.dart';
import 'package:logistics_app/core/realtime/realtime_bus.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/planning_controllers.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/supervisor_controllers.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_fleet_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plan_detail_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plans_screen.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// Flota y planes EN TIEMPO REAL: con socket no se refresca por tiempo; los
// eventos actualizan la pantalla. Sin socket vuelve el refresco de respaldo.

RealtimeEvent _event(String name, [Map<String, Object?> data = const {}]) =>
    (channel: 'c', name: name, data: data);

AutoPlanRun _run(AutoPlanRunStatus status) => AutoPlanRun(
  id: 'run-1',
  planDate: DateTime(2026, 11, 15),
  strategy: AutoPlanRunStrategy.optimization,
  status: status,
  requestedAt: DateTime(2026, 11, 15, 8),
  trucksPlanned: 3,
  stopsPlanned: 12,
  unassignedCount: 0,
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeSupervisorRepository repo,
  Widget screen,
) async {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supervisorRepositoryProvider.overrideWithValue(repo),
        canPlanProvider.overrideWithValue(true),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('flota en vivo', () {
    testWidgets('con socket: aplica la posición sin volver a pedir la lista', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
      final c = await _pump(tester, repo, const SupervisorFleetScreen());
      expect(repo.fleetCalls, 1);
      // La pantalla a la vista pide el tema de flota.
      expect(c.read(realtimeBusProvider).topics, contains(RealtimeTopic.fleet));

      // Se conecta el socket: se pide una vez (por lo perdido) y nunca más.
      c.read(realtimeLiveProvider.notifier).set({RealtimeTopic.fleet});
      await _settle(tester);
      expect(repo.fleetCalls, 2);
      await tester.pump(fleetRefreshInterval * 4);
      await _settle(tester);
      expect(repo.fleetCalls, 2, reason: 'con socket no refresca por tiempo');

      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.fleet,
            _event('fleet.position', {
              'vehicle_id': 'v1',
              'lat': -17.78,
              'lng': -63.18,
              'moving': false,
              'recorded_at': '2030-01-01T10:00:00Z',
            }),
          );
      await _settle(tester);
      expect(repo.fleetCalls, 2);
      final moved = c.read(fleetLiveProvider).value!.single;
      expect(moved.lat, -17.78);
      expect(moved.moving, isFalse);

      // Un camión nuevo se agrega.
      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.fleet,
            _event('fleet.position', {
              'vehicle_id': 'v2',
              'lat': -17.7,
              'lng': -63.1,
              'moving': true,
              'recorded_at': '2030-01-01T10:00:05Z',
            }),
          );
      await _settle(tester);
      expect(c.read(fleetLiveProvider).value, hasLength(2));

      // Un camión dado de baja se quita por id.
      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.fleet,
            _event('fleet.removed', {'vehicle_id': 'v1'}),
          );
      await _settle(tester);
      expect(c.read(fleetLiveProvider).value!.single.vehicleId, 'v2');
      expect(repo.fleetCalls, 2);
    });

    testWidgets('evento incompleto: se pide la lista entera', (tester) async {
      final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
      final c = await _pump(tester, repo, const SupervisorFleetScreen());
      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.fleet,
            _event('fleet.position', {'vehicle_id': 'v1'}),
          );
      await _settle(tester);
      expect(repo.fleetCalls, 2);
    });

    testWidgets('se cae el socket: vuelve el refresco de respaldo', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
      final c = await _pump(tester, repo, const SupervisorFleetScreen());
      c.read(realtimeLiveProvider.notifier).set({RealtimeTopic.fleet});
      await _settle(tester);
      expect(repo.fleetCalls, 2);

      c.read(realtimeLiveProvider.notifier).set({});
      await _settle(tester);
      await tester.pump(fleetRefreshInterval);
      await _settle(tester);
      expect(repo.fleetCalls, 3);
    });

    testWidgets('al salir de la pantalla deja de escuchar', (tester) async {
      final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
      final container = ProviderContainer(
        overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SupervisorFleetScreen()),
        ),
      );
      await _settle(tester);
      expect(container.read(realtimeBusProvider).topics, {RealtimeTopic.fleet});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox.shrink(),
        ),
      );
      expect(container.read(realtimeBusProvider).topics, isEmpty);
    });
  });

  group('planes', () {
    testWidgets('la corrida avanza por socket, sin consultar por tiempo', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()
        ..run = _run(AutoPlanRunStatus.processing);
      final c = await _pump(tester, repo, const SupervisorPlansScreen());
      c.read(realtimeLiveProvider.notifier).set({RealtimeTopic.planning});
      await _settle(tester);
      expect(find.text('Planificando…'), findsOneWidget);

      // Termina en el backend, pero sin evento la app no pregunta.
      repo.run = _run(AutoPlanRunStatus.completed);
      await tester.pump(const Duration(seconds: 30));
      await _settle(tester);
      expect(find.text('Planificando…'), findsOneWidget);

      final plansBefore = repo.plansCalls;
      // Sin plan_date el evento vale para el día que se mira (no se ata a una
      // fecha fija, que se rompía al cambiar el día).
      c
          .read(realtimeBusProvider)
          .dispatch(RealtimeTopic.planning, _event('planning.run.updated'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Planificado: 3 camiones, 12 paradas.'), findsOneWidget);
      expect(repo.plansCalls, greaterThan(plansBefore));
    });

    testWidgets('un plan cambiado en otro teléfono refresca la lista', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository();
      final c = await _pump(tester, repo, const SupervisorPlansScreen());
      final before = repo.plansCalls;
      final today = c.read(plansDateProvider);
      String ymd(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      // De otro día: no toca esta lista.
      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.planning,
            _event('plans.updated', {
              'plan_date': ymd(today.add(const Duration(days: 3))),
            }),
          );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repo.plansCalls, before);

      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.planning,
            _event('plans.updated', {'plan_date': ymd(today)}),
          );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repo.plansCalls, before + 1);
    });

    testWidgets('el detalle se refresca solo si cambió ESE plan', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()..planValue = plan(id: 'p1');
      final c = await _pump(
        tester,
        repo,
        const SupervisorPlanDetailScreen(planId: 'p1'),
      );
      await tester.pumpAndSettle();
      final before = repo.planCalls;

      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.planning,
            _event('plans.updated', {'plan_id': 'otro'}),
          );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repo.planCalls, before);

      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.planning,
            _event('plans.updated', {'plan_id': 'p1'}),
          );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repo.planCalls, before + 1);
    });
  });

  group('eliminar plan', () {
    Future<void> open(
      WidgetTester tester,
      FakeSupervisorRepository repo,
    ) async {
      tester.view.physicalSize = const Size(1200, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supervisorRepositoryProvider.overrideWithValue(repo),
            canPlanProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const SupervisorPlanDetailScreen(planId: 'p1'),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('pide confirmación, borra y cierra el detalle', (tester) async {
      final repo = FakeSupervisorRepository()
        ..planValue = plan(id: 'p1', status: PlanStatus.draft);
      await open(tester, repo);

      await tester.ensureVisible(find.text('Eliminar plan'));
      await tester.tap(find.text('Eliminar plan'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar el plan?'), findsOneWidget);
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(repo.deletedPlans, ['p1']);
      expect(find.text('Detalle del plan'), findsNothing);
      expect(find.text('Abrir'), findsOneWidget);
    });

    testWidgets('un plan publicado no se puede eliminar', (tester) async {
      final repo = FakeSupervisorRepository()
        ..planValue = plan(id: 'p1', status: PlanStatus.published);
      await open(tester, repo);
      expect(find.text('Eliminar plan'), findsNothing);
    });

    testWidgets('borrado desde otro teléfono: el detalle se cierra solo', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()
        ..planValue = plan(id: 'p1', status: PlanStatus.draft);
      await open(tester, repo);
      final c = ProviderScope.containerOf(
        tester.element(find.text('Detalle del plan')),
      );
      final before = repo.planCalls;

      c
          .read(realtimeBusProvider)
          .dispatch(
            RealtimeTopic.planning,
            _event('plans.updated', {'plan_id': 'p1', 'deleted': true}),
          );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Detalle del plan'), findsNothing);
      expect(repo.planCalls, before, reason: 'no se vuelve a pedir');
    });
  });

  test('evento de planificación: ¿es del día que se mira?', () {
    final day = DateTime(2026, 11, 15);
    expect(planEventIsFor(_event('x'), day), isTrue);
    expect(
      planEventIsFor(_event('x', {'plan_date': '2026-11-15'}), day),
      isTrue,
    );
    expect(
      planEventIsFor(_event('x', {'plan_date': '2026-11-15T00:00:00Z'}), day),
      isTrue,
    );
    expect(
      planEventIsFor(_event('x', {'plan_date': '2026-11-16'}), day),
      isFalse,
    );
  });
}
