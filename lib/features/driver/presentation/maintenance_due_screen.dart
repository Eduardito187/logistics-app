import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/entities/due_maintenance_item.dart';
import 'controllers/fleet_ops_controllers.dart';
import 'widgets/due_card.dart';

/// Mantenimiento preventivo por vencer de la flota (solo lectura). El chofer
/// consulta qué le toca al/los vehículos, con un chip de urgencia por item.
class MaintenanceDueScreen extends ConsumerWidget {
  const MaintenanceDueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(dueMaintenanceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mantenimiento')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dueMaintenanceProvider),
        child: AsyncValueView<List<DueMaintenanceItem>>(
          value: due,
          onRetry: () => ref.invalidate(dueMaintenanceProvider),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.verified,
                    title: 'Todo al día',
                    message: 'No hay mantenimientos por vencer.',
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => DueCard(item: items[index]),
            );
          },
        ),
      ),
    );
  }
}
