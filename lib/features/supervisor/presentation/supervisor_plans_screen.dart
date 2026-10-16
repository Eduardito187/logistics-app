import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/plan.dart';
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
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.alt_route,
                          title: 'Sin planes para este día',
                          message:
                              'Elige otra fecha o genera la planificación.',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        PlanCard(plan: data[index]),
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
