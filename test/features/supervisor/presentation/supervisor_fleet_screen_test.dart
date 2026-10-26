import 'dart:async';

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

  group('refresco automático', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('a la vista refresca cada intervalo', (tester) async {
      final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
      await _pumpWidget(tester, repo);
      await settle(tester);
      expect(repo.fleetCalls, 1);

      await tester.pump(fleetRefreshInterval);
      await settle(tester);
      expect(repo.fleetCalls, 2);

      await tester.pump(fleetRefreshInterval);
      await settle(tester);
      expect(repo.fleetCalls, 3);
    });

    testWidgets('en segundo plano se detiene y al volver refresca', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
      await _pumpWidget(tester, repo);
      await settle(tester);
      expect(repo.fleetCalls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(fleetRefreshInterval * 4);
      await settle(tester);
      expect(repo.fleetCalls, 1, reason: 'sin pedidos en segundo plano');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(repo.fleetCalls, 2, reason: 'refresca enseguida al volver');

      await tester.pump(fleetRefreshInterval);
      await settle(tester);
      expect(repo.fleetCalls, 3, reason: 'y retoma el intervalo');
    });

    testWidgets('tapada por otra pantalla se detiene', (tester) async {
      final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            home: const SupervisorFleetScreen(),
          ),
        ),
      );
      await settle(tester);
      expect(repo.fleetCalls, 1);

      unawaited(
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Encima')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(fleetRefreshInterval * 3);
      await settle(tester);
      expect(repo.fleetCalls, 1, reason: 'sin pedidos mientras está tapada');

      navigatorKey.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(repo.fleetCalls, 2, reason: 'refresca al volver a la vista');
    });

    testWidgets('al salir de la pantalla no queda ningún timer', (
      tester,
    ) async {
      final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
      await _pumpWidget(tester, repo);
      await settle(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(fleetRefreshInterval * 2);
      expect(repo.fleetCalls, 1);
    });
  });
}
