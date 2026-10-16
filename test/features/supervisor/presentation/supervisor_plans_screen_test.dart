import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_plans_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plan_card.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/plans_date_bar.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// SupervisorPlansScreen: barra de fecha + lista de planes del día (datos, vacío,
// error).

Future<void> _pump(WidgetTester tester, FakeSupervisorRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: SupervisorPlansScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

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
    expect(find.byType(PlanCard), findsNWidgets(2));
    expect(find.text('Camión CAM-1'), findsOneWidget);
    expect(find.text('Camión CAM-2'), findsOneWidget);
  });

  testWidgets('sin planes muestra el estado vacío', (tester) async {
    final repo = FakeSupervisorRepository()..plansByDate = const [];
    await _pump(tester, repo);

    expect(find.text('Sin planes para este día'), findsOneWidget);
    // La barra de fecha sigue visible para poder cambiar de día.
    expect(find.byType(PlansDateBar), findsOneWidget);
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
}
