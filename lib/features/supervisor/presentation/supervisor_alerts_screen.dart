import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/alert.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/alert_card.dart';

/// Alertas de telemetría: lista con filtro y reconocimiento (acknowledge).
class SupervisorAlertsScreen extends ConsumerWidget {
  const SupervisorAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final unacknowledgedOnly = ref.watch(alertsFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Sin reconocer'),
                  selected: unacknowledgedOnly,
                  onSelected: (_) => ref
                      .read(alertsFilterProvider.notifier)
                      .setUnacknowledgedOnly(value: true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: !unacknowledgedOnly,
                  onSelected: (_) => ref
                      .read(alertsFilterProvider.notifier)
                      .setUnacknowledgedOnly(value: false),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(alertsProvider),
              child: AsyncValueView<List<Alert>>(
                value: alerts,
                onRetry: () => ref.invalidate(alertsProvider),
                data: (data) {
                  if (data.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.notifications_off,
                          title: 'Sin alertas',
                          message: 'No hay alertas que reconocer por ahora.',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        AlertCard(alert: data[index]),
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
