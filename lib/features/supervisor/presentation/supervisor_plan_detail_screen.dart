import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/plan.dart';
import '../../../core/widgets/async_value_view.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/plan_detail_body.dart';

/// Detalle (solo lectura) de un plan de ruta: datos del plan y camión, su ETA
/// y la secuencia de paradas. La generación/publicación/edición de planes es
/// tarea de oficina (admin del backend), no de la app de campo.
class SupervisorPlanDetailScreen extends ConsumerWidget {
  const SupervisorPlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planDetailProvider(planId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del plan')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(planDetailProvider(planId));
          ref.invalidate(planEtaProvider(planId));
        },
        child: AsyncValueView<Plan>(
          value: plan,
          onRetry: () => ref.invalidate(planDetailProvider(planId)),
          data: (data) => PlanDetailBody(plan: data, planId: planId),
        ),
      ),
    );
  }
}
