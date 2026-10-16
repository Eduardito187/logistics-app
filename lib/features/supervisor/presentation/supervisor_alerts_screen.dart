import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/alert.dart';
import '../../../core/layout/adaptive_card_rows.dart';
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
            // Wrap: con letra grande en un teléfono chico los dos filtros no
            // entran en una fila y bajan a la siguiente en vez de desbordar.
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Sin reconocer'),
                  selected: unacknowledgedOnly,
                  onSelected: (_) => ref
                      .read(alertsFilterProvider.notifier)
                      .setUnacknowledgedOnly(value: true),
                ),
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
                      physics: const AlwaysScrollableScrollPhysics(),
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
                  // Perezosa y en columnas (1 en teléfono, 2–3 en tablet). La
                  // key por id conserva el estado "reconociendo…" de cada
                  // tarjeta aunque la lista cambie al refrescar.
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverAdaptiveCardRows(
                          itemCount: data.length,
                          itemBuilder: (context, index) => AlertCard(
                            key: ValueKey(data[index].id),
                            alert: data[index],
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
