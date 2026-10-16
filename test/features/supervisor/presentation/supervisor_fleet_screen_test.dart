import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_fleet_screen.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/fleet_map.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// SupervisorFleetScreen: flota en vivo. Con posiciones muestra el mapa; sin
// posiciones, el estado vacío; ante error, el estado de error.

Future<void> _pumpWidget(
  WidgetTester tester,
  FakeSupervisorRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: SupervisorFleetScreen()),
    ),
  );
}

void main() {
  testWidgets('con posiciones arma el mapa de flota', (tester) async {
    final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
    await _pumpWidget(tester, repo);
    // Se resuelve el futuro y se construye el mapa sin usar pumpAndSettle (el
    // tile layer y el clustering programan trabajo continuo).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(FleetMap), findsOneWidget);
  });

  testWidgets('sin posiciones muestra el estado vacío', (tester) async {
    final repo = FakeSupervisorRepository()..fleet = const [];
    await _pumpWidget(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Sin camiones en vivo'), findsOneWidget);
    expect(
      find.text('No hay posiciones de telemetría por ahora.'),
      findsOneWidget,
    );
    expect(find.byType(FleetMap), findsNothing);
  });

  testWidgets('en error muestra el estado de error con reintento', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..fleetError = const ApiException(status: 500, title: 'x');
    await _pumpWidget(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
