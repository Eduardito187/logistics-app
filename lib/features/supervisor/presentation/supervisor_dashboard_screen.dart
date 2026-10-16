import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_view.dart';
import '../domain/dashboard_metrics.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/dashboard_body.dart';

/// Tablero del día: tarjetas con las métricas derivadas de envíos, planes y
/// alertas (estilo "finanzas" de los mockups).
class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final date = ref.watch(plansDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tablero del día')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardMetricsProvider),
        child: AsyncValueView<DashboardMetrics>(
          value: metrics,
          onRetry: () => ref.invalidate(dashboardMetricsProvider),
          data: (data) => DashboardBody(metrics: data, date: date),
        ),
      ),
    );
  }
}
