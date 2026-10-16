import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/notification_view.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/notifications_controller.dart';
import 'widgets/notification_tile.dart';
import 'widgets/push_status_card.dart';

/// Bandeja de notificaciones de la operación. Lista global más reciente primero
/// con pull-to-refresh. Cada fila abre el detalle.
class NotificationsListScreen extends ConsumerWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: PushStatusCard(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(notificationsListProvider.future),
              child: AsyncValueView<List<NotificationView>>(
                value: notifications,
                onRetry: () => ref.invalidate(notificationsListProvider),
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'Sin notificaciones',
                          message: 'No hay notificaciones en la operación por ahora.',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        NotificationTile(notification: items[index]),
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
