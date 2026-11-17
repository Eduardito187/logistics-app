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
import 'controllers/plans_filter_notifier.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/plan_card.dart';
import 'widgets/planning_actions_card.dart';
import 'widgets/plans_date_bar.dart';
import 'widgets/plans_filter_bar.dart';

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
    final filter = ref.watch(plansFilterProvider);
    // La fila de filtros solo tiene sentido cuando ese día SÍ hay planes: no
    // se muestra mientras carga ni sobre el vacío "Sin planes para este día".
    final hasPlans = (plans.value ?? const <Plan>[]).isNotEmpty;

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
            if (hasPlans) const PlansFilterBar(),
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
                    // Filtro cliente-side (estado + texto) sobre los planes del
                    // día: el endpoint solo filtra por fecha.
                    final visible = filterPlans(data, filter);
                    if (visible.isEmpty) {
                      // Hay planes ese día, pero ninguno pasa el filtro: vacío
                      // distinto, con acción para limpiarlo.
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyState(
                            icon: AppIcon.search,
                            title: 'Ningún plan coincide con el filtro',
                            message: 'Probá con otra placa, chofer o estado.',
                            action: FilledButton.tonal(
                              key: const Key('plans-clear-filter'),
                              onPressed: () => ref
                                  .read(plansFilterProvider.notifier)
                                  .clear(),
                              child: const Text('Limpiar filtro'),
                            ),
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
                            itemCount: visible.length,
                            itemBuilder: (context, index) => PlanCard(
                              key: ValueKey(visible[index].id),
                              plan: visible[index],
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
