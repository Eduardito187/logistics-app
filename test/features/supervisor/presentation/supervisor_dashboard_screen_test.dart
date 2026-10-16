import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/supervisor_controllers.dart';
import 'package:logistics_app/features/supervisor/domain/dashboard_metrics.dart';
import 'package:logistics_app/features/supervisor/presentation/supervisor_dashboard_screen.dart';

// Pantalla del tablero del supervisor. Se override el provider de datos de alto
// nivel (dashboardMetricsProvider) con valores de ejemplo para renderizar sin
// tocar Dio real, y se cubren los estados de dato y de error.

const _metrics = DashboardMetrics(
  received: 2,
  planned: 1,
  inExecution: 4,
  delivered: 6,
  failed: 2,
  cancelled: 0,
  activePlans: 3,
  openAlerts: 5,
);

Future<void> _pump(
  WidgetTester tester,
  Future<DashboardMetrics> Function() load,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dashboardMetricsProvider.overrideWith((ref) => load())],
      child: const MaterialApp(home: SupervisorDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con datos muestra las métricas del día', (tester) async {
    await _pump(tester, () async => _metrics);

    expect(find.text('Tablero del día'), findsOneWidget);
    // total = 15 envíos, 5 alertas sin reconocer.
    expect(find.text('15 envíos del día en total'), findsOneWidget);
    expect(find.text('5 alertas sin reconocer'), findsOneWidget);
    // Tarjetas de métricas.
    expect(find.text('Entregadas'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // entregadas
    // Cumplimiento = 6 / (6+2) = 75 %.
    expect(find.text('75%'), findsOneWidget);
  });

  testWidgets('en error muestra el estado vacío con reintento', (tester) async {
    const error = ApiException(status: 500, title: 'Falló el servidor');
    await _pump(tester, () async => throw error);

    expect(find.text('No se pudo cargar'), findsOneWidget);
    // El mensaje lo decide ApiException.message (el 5xx tiene su copy propia).
    expect(find.text(error.message), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
