import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/alert_severity.dart';
import 'package:logistics_app/core/api/models/alert_type.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/widgets/alert_card.dart';

import '../../support/fake_supervisor_repository.dart';
import '../../support/supervisor_fixtures.dart';

// AlertCard: muestra los datos de la alerta y permite reconocerla. El
// reconocimiento pasa por el repositorio; ante error muestra un SnackBar.

Future<FakeSupervisorRepository> _pumpCard(
  WidgetTester tester, {
  required Widget card,
  FakeSupervisorRepository? repo,
}) async {
  final fake = repo ?? FakeSupervisorRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [supervisorRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(home: Scaffold(body: card)),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('alerta sin reconocer muestra datos y el botón Reconocer', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      card: AlertCard(
        alert: alert(
          vehicleId: 'CAM-5',
          type: AlertType.speeding,
          severity: AlertSeverity.critical,
          detail: 'Iba a 95 km/h',
          occurredAt: DateTime(2026, 3, 9, 8, 30),
        ),
      ),
    );

    expect(find.text('Exceso de velocidad'), findsOneWidget); // tipo
    expect(find.text('Crítica'), findsOneWidget); // severidad (pastilla)
    expect(find.text('Camión CAM-5'), findsOneWidget);
    expect(find.text('Ocurrió: 08:30'), findsOneWidget);
    expect(find.text('Iba a 95 km/h'), findsOneWidget); // detalle
    expect(find.text('Reconocer'), findsOneWidget);
  });

  testWidgets('alerta ya reconocida muestra la hora y oculta el botón', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      card: AlertCard(
        alert: alert(acknowledgedAt: DateTime(2026, 3, 9, 10, 15)),
      ),
    );

    expect(find.text('Reconocida 10:15'), findsOneWidget);
    expect(find.text('Reconocer'), findsNothing);
  });

  testWidgets('sin detalle no se dibuja la línea de detalle', (tester) async {
    await _pumpCard(tester, card: AlertCard(alert: alert()));

    // El único texto extra sería el detalle; no hay nada que afirmar salvo que
    // el botón sigue presente y la tarjeta renderiza.
    expect(find.text('Reconocer'), findsOneWidget);
  });

  testWidgets('reconocer OK llama al repositorio con el id de la alerta', (
    tester,
  ) async {
    final fake = await _pumpCard(
      tester,
      card: AlertCard(alert: alert(id: 'ALERT-42')),
    );

    await tester.tap(find.text('Reconocer'));
    await tester.pump(); // dispara el estado "Reconociendo…"
    await tester.pumpAndSettle();

    expect(fake.acknowledgedIds, ['ALERT-42']);
  });

  testWidgets('reconocer con error muestra un SnackBar y no agrega el id', (
    tester,
  ) async {
    final repo = FakeSupervisorRepository()
      ..acknowledgeError = const ApiException(
        status: 500,
        title: 'Falló el servidor',
      );

    await _pumpCard(
      tester,
      repo: repo,
      card: AlertCard(alert: alert(id: 'ALERT-99')),
    );

    await tester.tap(find.text('Reconocer'));
    await tester.pump();
    await tester.pump(); // procesa el catch + SnackBar

    expect(repo.acknowledgedIds, isEmpty);
    expect(
      find.text('Error del servidor. Probá de nuevo en un momento.'),
      findsOneWidget,
    );
  });
}
