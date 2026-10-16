import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/alert_type.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_alerts_screen.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// SupervisorAlertsScreen: filtro (sin reconocer / todas), lista con datos, vacío
// y error. El filtro cambia el argumento `acknowledged` que se pide al backend.

Future<void> _pump(WidgetTester tester, FakeSupervisorRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: SupervisorAlertsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos muestra los chips y la lista de alertas', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..alerts = [
        alert(id: 'a1', type: AlertType.speeding),
        alert(id: 'a2', type: AlertType.excessiveIdle),
      ];
    await _pump(tester, repo);

    expect(find.text('Alertas'), findsOneWidget); // título
    expect(find.text('Sin reconocer'), findsOneWidget); // chip
    expect(find.text('Todas'), findsOneWidget); // chip
    expect(find.text('Exceso de velocidad'), findsOneWidget);
    expect(find.text('Ralentí excesivo'), findsOneWidget);
  });

  testWidgets('por defecto pide solo las no reconocidas (acknowledged=false)', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()..alerts = const [];
    await _pump(tester, repo);

    expect(repo.lastAlertsAcknowledgedArg, isFalse);
  });

  testWidgets('tocar "Todas" pide sin filtro (acknowledged=null)', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()..alerts = const [];
    await _pump(tester, repo);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();

    expect(repo.lastAlertsAcknowledgedArg, isNull);
  });

  testWidgets('sin alertas muestra el estado vacío', (tester) async {
    final repo = FakeSupervisorRepository()..alerts = const [];
    await _pump(tester, repo);

    expect(find.text('Sin alertas'), findsOneWidget);
    expect(
      find.text('No hay alertas que reconocer por ahora.'),
      findsOneWidget,
    );
  });

  testWidgets('en error muestra el estado de error con reintento', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..alertsError = const ApiException(status: 500, title: 'x');
    await _pump(tester, repo);

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
