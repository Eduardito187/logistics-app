import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/plan.dart';
import '../../../core/widgets/async_value_view.dart';
import 'controllers/planning_controllers.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/plan_detail_body.dart';

/// Detalle de un plan de ruta: datos del plan y camión, su ETA y la secuencia
/// de paradas. Para el supervisor es de solo lectura; el planificador y el
/// administrador pueden ordenar, completar y publicar un plan sin publicar.
///
/// [initial] es el plan de la lista (llega por `extra` al tocar la tarjeta):
/// se muestra al instante mientras el detalle fresco llega, sin spinner. El
/// plan y su ETA se piden **en paralelo** (antes el ETA esperaba al plan).
class SupervisorPlanDetailScreen extends ConsumerWidget {
  const SupervisorPlanDetailScreen({
    super.key,
    required this.planId,
    this.initial,
  });

  final String planId;
  final Plan? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planDetailProvider(planId));
    // Arranca el ETA ya (la sección que lo muestra recién se arma cuando hay
    // plan; sin este watch quedaba en cadena detrás del plan).
    ref.watch(planEtaProvider(planId));

    // Con el plan de la lista, la carga inicial no muestra spinner; un error
    // sí se muestra (con reintento) aunque haya dato inicial.
    final seed = initial;
    final shown = plan.isLoading && !plan.hasValue && seed != null
        ? AsyncData<Plan>(seed)
        : plan;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del plan')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(planDetailProvider(planId));
          ref.invalidate(planEtaProvider(planId));
        },
        child: AsyncValueView<Plan>(
          value: shown,
          onRetry: () => ref.invalidate(planDetailProvider(planId)),
          data: (data) => PlanDetailBody(
            plan: data,
            planId: planId,
            canPlan: ref.watch(canPlanProvider),
          ),
        ),
      ),
    );
  }
}
