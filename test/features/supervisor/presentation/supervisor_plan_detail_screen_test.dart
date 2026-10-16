import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plan_detail_screen.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';
import '../../../support/button_finders.dart';

// SupervisorPlanDetailScreen: detalle SOLO lectura de un plan. Cabecera, métricas
// (paradas + ETA final), sección de ETA por parada y secuencia de paradas. No
// debe ofrecer ninguna acción de generar/publicar/editar (eso es de oficina).

Future<void> _pump(WidgetTester tester, FakeSupervisorRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: SupervisorPlanDetailScreen(planId: 'p1')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra cabecera, métricas, secuencia y ETA por parada', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..planValue = plan(
        id: 'p1',
        vehicleId: 'CAM-7',
        stops: [
          plannedStop(
            sequence: 1,
            loadOrder: 2,
            shipmentId: 'S1',
            etaAt: DateTime(2026, 3, 9, 10, 0),
          ),
          plannedStop(
            sequence: 2,
            loadOrder: 1,
            shipmentId: 'S2',
            etaAt: DateTime(2026, 3, 9, 13, 30),
          ),
        ],
      )
      ..planEtaValue = planEtaData(
        planId: 'p1',
        stops: [
          stopEta(
            sequence: 1,
            shipmentId: 'E1',
            etaAt: DateTime(2026, 3, 9, 10, 0),
          ),
        ],
      );

    await _pump(tester, repo);

    expect(find.text('Detalle del plan'), findsOneWidget); // título
    expect(find.text('Camión CAM-7'), findsOneWidget);
    expect(find.text('Publicado'), findsOneWidget); // pastilla de estado
    expect(find.text('Fecha'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('p1'), findsOneWidget); // valor del id
    // Métricas: etiqueta de paradas y ETA final (última por secuencia con ETA).
    // El conteo numérico "2" colisiona con el avatar de la parada 2, así que se
    // afirma por etiqueta; la ETA final (13:30) es la hora del último stop.
    expect(find.text('Paradas'), findsOneWidget);
    expect(find.text('ETA final'), findsOneWidget);
    expect(find.text('13:30'), findsOneWidget);
    // Secuencia de paradas (StopTile) y ETA por parada (EtaRow), con ids propios.
    expect(find.text('Secuencia de paradas'), findsOneWidget);
    expect(find.text('Envío S1'), findsOneWidget);
    expect(find.text('Envío S2'), findsOneWidget);
    expect(find.text('ETA por parada'), findsOneWidget);
    expect(find.text('Envío E1'), findsOneWidget);
  });

  testWidgets(
    'es solo lectura: no ofrece acciones de generar/publicar/editar',
    (tester) async {
      final repo = FakeSupervisorRepository()
        ..planValue = plan(
          id: 'p1',
          stops: [plannedStop(sequence: 1, loadOrder: 1)],
        )
        ..planEtaValue = planEtaData();

      await _pump(tester, repo);

      for (final forbidden in const [
        'Publicar',
        'Generar',
        'Generar plan',
        'Proponer',
        'Reordenar',
        'Asignar',
        'Editar',
      ]) {
        expect(
          find.text(forbidden),
          findsNothing,
          reason: 'No debe existir "$forbidden"',
        );
      }
      // No hay botones de acción primaria (FilledButton) en el detalle.
      expect(findButton<FilledButton>(), findsNothing);
    },
  );

  testWidgets('plan sin paradas muestra el texto correspondiente', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..planValue = plan(id: 'p1', stops: const [])
      ..planEtaValue = planEtaData(stops: const []);

    await _pump(tester, repo);

    expect(find.text('El plan todavía no tiene paradas.'), findsOneWidget);
  });

  testWidgets('ETA sin calcular muestra el texto de la sección', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..planValue = plan(
        id: 'p1',
        stops: [plannedStop(sequence: 1, loadOrder: 1)],
      )
      ..planEtaValue = planEtaData(stops: const []);

    await _pump(tester, repo);

    expect(find.text('Sin ETA calculada todavía.'), findsOneWidget);
  });

  testWidgets('un fallo de ETA no tumba el detalle: error solo en su sección', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..planValue = plan(id: 'p1', vehicleId: 'CAM-7', stops: const [])
      ..planEtaError = const ApiException(status: 500, title: 'x');

    await _pump(tester, repo);

    // El detalle del plan sigue visible...
    expect(find.text('Camión CAM-7'), findsOneWidget);
    // ...y el error aparece dentro de la sección de ETA.
    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('si el plan falla al cargar, la pantalla muestra el error', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..planError = const ApiException(status: 500, title: 'x')
      ..planEtaValue = planEtaData();

    await _pump(tester, repo);

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsWidgets);
  });
}
