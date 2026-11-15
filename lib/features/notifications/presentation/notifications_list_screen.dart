import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/notification_view.dart';
import '../../../core/icons/icons.dart';
import '../../../core/layout/nav_clearance.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/push/push_arrived.dart';
import '../../../core/realtime/realtime_bus.dart';
import '../data/datasources/inbox_remote_data_source.dart';
import 'controllers/notifications_controller.dart';
import 'widgets/inbox_section.dart';
import 'widgets/notification_tile.dart';
import 'widgets/push_status_card.dart';

/// Bandeja de notificaciones de la operación. Lista global más reciente primero
/// con pull-to-refresh. Cada fila abre el detalle.
///
/// Todo va en un único `CustomScrollView` (tarjeta de push + lista perezosa):
/// en teléfonos chicos la tarjeta se desplaza con la lista en vez de dejarle
/// poco alto, y el estado vacío/error también se puede refrescar tirando. El
/// contenido pasa por debajo del footer flotante (padding inferior).
///
/// Se mantiene AL DÍA sola mientras está a la vista: en tiempo real por el
/// socket del usuario, cuando llega un push y al volver a la app. Solo si no
/// hay socket (entorno sin tiempo real o conexión caída) refresca cada
/// [refreshEvery] como respaldo. Los avisos de la empresa van en esta misma
/// pantalla (son una notificación más).
class NotificationsListScreen extends ConsumerStatefulWidget {
  const NotificationsListScreen({
    super.key,
    this.refreshEvery = const Duration(seconds: 20),
  });

  final Duration refreshEvery;

  @override
  ConsumerState<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState
    extends ConsumerState<NotificationsListScreen> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  /// Refresco por tiempo SOLO sin socket: con tiempo real no hace falta.
  void _syncFallback({required bool live}) {
    if (live) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(widget.refreshEvery, (_) => _refresh());
  }

  /// Vuelve a pedir las dos bandejas. La lista actual sigue visible mientras
  /// llega la nueva (sin spinner).
  void _refresh() {
    if (!mounted) return;
    ref.invalidate(notificationsListProvider);
    ref.invalidate(inboxPreviewProvider);
    ref.invalidate(inboxUnreadCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    _syncFallback(
      live: ref.watch(realtimeTopicLiveProvider(RealtimeTopic.user)),
    );
    // Llegó un push (o un evento del socket) con la app abierta: refrescar ya.
    ref.listen(pushArrivedProvider, (_, _) => _refresh());
    final notifications = ref.watch(notificationsListProvider);
    final limit = ref.watch(notificationsLimitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ResponsiveBody(
        child: RefreshIndicator(
          onRefresh: () {
            ref.invalidate(inboxPreviewProvider);
            return ref.refresh(notificationsListProvider.future);
          },
          child: CustomScrollView(
            // Permite tirar para refrescar aunque la lista no llene la pantalla.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: PushStatusCard()),
              ),
              // Avisos que el administrador le envió al usuario (por rol, por
              // tienda o a él), en esta misma pantalla.
              const SliverToBoxAdapter(child: InboxSection()),
              ...switch (notifications) {
                // Con datos (también mientras recarga): lista perezosa.
                AsyncValue(:final value?, hasError: false) =>
                  value.isEmpty
                      ? const [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyState(
                              icon: AppIcon.alertsOff,
                              title: 'Sin notificaciones',
                              message:
                                  'No hay notificaciones en la operación por '
                                  'ahora.',
                            ),
                          ),
                        ]
                      : [
                          _NotificationsSliver(items: value),
                          // El endpoint no tiene cursor: si llegó una página
                          // llena puede haber más; "Ver más" sube el límite.
                          if (value.length >= limit)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                navScrollBottomPadding(context),
                              ),
                              sliver: SliverToBoxAdapter(
                                child: _MoreFooter(
                                  canShowMore: limit < notificationsMaxLimit,
                                  loading: notifications.isLoading,
                                  onShowMore: () => ref
                                      .read(notificationsLimitProvider.notifier)
                                      .showMore(),
                                ),
                              ),
                            )
                          else
                            // Sin footer: el último ítem necesita el respiro
                            // bajo el footer flotante.
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: navScrollBottomPadding(context),
                              ),
                            ),
                        ],
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

/// Pie de la bandeja: botón grande "Ver más" o, al llegar al tope en memoria,
/// un aviso de que solo se muestran las más recientes.
class _MoreFooter extends StatelessWidget {
  const _MoreFooter({
    required this.canShowMore,
    required this.loading,
    required this.onShowMore,
  });

  final bool canShowMore;
  final bool loading;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    if (!canShowMore) {
      return Text(
        'Se muestran las $notificationsMaxLimit más recientes.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }
    return OutlinedButton.icon(
      onPressed: loading ? null : onShowMore,
      icon: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const AnimatedAppIcon(AppIcon.expandMore),
      label: const Text('Ver más notificaciones'),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => NotificationTile(
          key: ValueKey(items[index].id),
          notification: items[index],
        ),
      ),
    );
  }
}
