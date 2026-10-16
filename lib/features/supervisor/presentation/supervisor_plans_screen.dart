import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/plan.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/plan_card.dart';
import 'widgets/plans_date_bar.dart';

/// Rutas/planes en curso: lista de planes del día con su estado y ETA.
class SupervisorPlansScreen extends ConsumerWidget {
  const SupervisorPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final date = ref.watch(plansDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rutas en curso')),
      body: Column(
        children: [
          PlansDateBar(date: date),
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
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.alt_route,
                          title: 'Sin planes para este día',
                          message:
                              'Elige otra fecha o espera a que se publique la planificación.',
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
    );
  }
}
