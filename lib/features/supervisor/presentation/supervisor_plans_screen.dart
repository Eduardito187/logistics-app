import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/plan.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/realtime/realtime_bus.dart';
import '../../../core/realtime/realtime_listener.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/planning_controllers.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/plan_card.dart';
import 'widgets/planning_actions_card.dart';
import 'widgets/plans_date_bar.dart';

/// Rutas/planes en curso: lista de planes del día con su estado y ETA. Quien
/// planifica (planificador, administrador) además ve las acciones del día:
/// planificar y publicar.
///
/// Se mantiene al día en tiempo real: si otro teléfono (o la planificación
/// automática) crea, cambia o publica un plan de este día, la lista se vuelve
/// a pedir sola.
class SupervisorPlansScreen extends ConsumerWidget {
  const SupervisorPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final date = ref.watch(plansDateProvider);
    final canPlan = ref.watch(canPlanProvider);

    return RealtimeListener(
      topic: RealtimeTopic.planning,
      onEvent: (event) {
        if (!planEventIsFor(event, ref.read(plansDateProvider))) return;
        switch (event.name) {
          case 'planning.run.updated':
            ref.invalidate(dailyPlanRunProvider);
            ref.invalidate(plansProvider);
          case 'plans.updated':
            ref.invalidate(plansProvider);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(canPlan ? 'Planificación' : 'Rutas en curso'),
        ),
        body: Column(
          children: [
            PlansDateBar(date: date),
            if (canPlan) PlanningActionsCard(date: date),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(plansProvider),
                child: AsyncValueView<List<Plan>>(
                  value: plans,
                  onRetry: () => ref.invalidate(plansProvider),
                  data: (data) {
                    if (data.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyState(
                            icon: AppIcon.plans,
                            title: 'Sin planes para este día',
                            message: canPlan
                                ? 'Tocá "Planificar el día" para armarlos.'
                                : 'Elige otra fecha o espera a que se publique la planificación.',
                          ),
                        ],
                      );
                    }
                    // Perezosa y en columnas (1 en teléfono, 2–3 en tablet).
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverAdaptiveCardRows(
                            itemCount: data.length,
                            itemBuilder: (context, index) => PlanCard(
                              key: ValueKey(data[index].id),
                              plan: data[index],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
