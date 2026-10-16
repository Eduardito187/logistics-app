import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_alerts_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plans_screen.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// El rol supervisor en la app de campo es SOLO monitoreo: la generación y
// publicación de planes es tarea de oficina (admin del backend). Ninguna
// pantalla del supervisor debe ofrecer esas acciones. Se verifica que no exista
// ningún texto de acción de generación/publicación/edición de planes.

const _forbiddenActions = [
  'Generar',
  'Generar plan',
  'Generar planificación',
  'Publicar',
  'Publicar plan',
  'Proponer',
  'Proponer plan',
  'Reordenar',
  'Asignar',
  'Asignar envío',
  'Editar plan',
  'Crear plan',
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  FakeSupervisorRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectNoForbiddenActions() {
  for (final action in _forbiddenActions) {
    expect(
      find.text(action),
      findsNothing,
      reason: 'El supervisor es solo lectura: no debe existir "$action"',
    );
  }
}

void main() {
  testWidgets('la lista de planes no ofrece generar/publicar', (tester) async {
    final repo = FakeSupervisorRepository()
      ..plansByDate = [plan(id: 'p1', vehicleId: 'CAM-1')];
    await _pump(tester, const SupervisorPlansScreen(), repo);

    _expectNoForbiddenActions();
  });

  testWidgets('la pantalla de alertas no ofrece generar/publicar', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()..alerts = [alert()];
    await _pump(tester, const SupervisorAlertsScreen(), repo);

    _expectNoForbiddenActions();
  });
}
