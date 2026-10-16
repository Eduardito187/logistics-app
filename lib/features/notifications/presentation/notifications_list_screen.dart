import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/notification_view.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/notifications_controller.dart';
import 'widgets/notification_tile.dart';
import 'widgets/push_status_card.dart';

/// Bandeja de notificaciones de la operación. Lista global más reciente primero
/// con pull-to-refresh. Cada fila abre el detalle.
///
/// Todo va en un único `CustomScrollView` (tarjeta de push + lista perezosa):
/// en teléfonos chicos la tarjeta se desplaza con la lista en vez de dejarle
/// poco alto, y el estado vacío/error también se puede refrescar tirando.
class NotificationsListScreen extends ConsumerWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ResponsiveBody(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsListProvider.future),
          child: CustomScrollView(
            // Permite tirar para refrescar aunque la lista no llene la pantalla.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: PushStatusCard()),
              ),
              ...switch (notifications) {
                // Con datos (también mientras recarga): lista perezosa.
                AsyncValue(:final value?, hasError: false) =>
                  value.isEmpty
                      ? const [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyState(
                              icon: Icons.notifications_off_outlined,
                              title: 'Sin notificaciones',
                              message:
                                  'No hay notificaciones en la operación por '
                                  'ahora.',
                            ),
                          ),
                        ]
                      : [_NotificationsSliver(items: value)],
                // Cargando o error: vista estándar, centrada en el resto.
                _ => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AsyncValueView<List<NotificationView>>(
                      value: notifications,
                      onRetry: () => ref.invalidate(notificationsListProvider),
                      data: (_) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista perezosa de notificaciones (solo construye las filas visibles).
class _NotificationsSliver extends StatelessWidget {
  const _NotificationsSliver({required this.items});

  final List<NotificationView> items;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            NotificationTile(notification: items[index]),
      ),
    );
  }
}
