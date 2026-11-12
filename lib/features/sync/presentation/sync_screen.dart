import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/offline/offline_queue.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_loader.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/offline/sync_queue_provider.dart';
import 'widgets/sync_action_tile.dart';

/// Estado de la cola offline: acciones de terreno pendientes de subir y las que
/// fallaron (datos rechazados), con reintento manual.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(syncQueueProvider);
    // `select`: solo reconstruye si cambia con/sin señal.
    final online = ref.watch(
      connectivityProvider.select((c) => c.value ?? true),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronización'),
        actions: const [_SyncNowButton()],
      ),
      body: queue.when(
        loading: () =>
            const Center(child: BrandLoader(message: 'Cargando cola...')),
        error: (e, _) => EmptyState(
          icon: AppIcon.error,
          title: 'No se pudo leer la cola',
          message: '$e',
        ),
        data: (actions) {
          if (actions.isEmpty) {
            return const EmptyState(
              icon: AppIcon.cloudDone,
              title: 'Todo sincronizado',
              message: 'No hay escaneos ni registros pendientes de subir.',
            );
          }
          return ResponsiveBody(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ConnectivityBanner(online: online),
                  ),
                ),
                // Lista perezosa: la cola puede crecer mucho sin señal.
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: actions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => SyncActionTile(
                      key: ValueKey(actions[i].id),
                      action: actions[i],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "Reintentar ahora": drena la cola y, mientras sincroniza, las flechas de la
/// nube giran (sutil: el escaneo nunca espera a la red). Al terminar queda la
/// nube con tilde hasta el próximo reintento.
class _SyncNowButton extends ConsumerStatefulWidget {
  const _SyncNowButton();

  @override
  ConsumerState<_SyncNowButton> createState() => _SyncNowButtonState();
}

class _SyncNowButtonState extends ConsumerState<_SyncNowButton> {
  bool _syncing = false;

  /// Cantidad de drenados terminados: 0 = todavía no se sincronizó a mano.
  int _runs = 0;

  Future<void> _drain() async {
    setState(() => _syncing = true);
    try {
      await ref.read(offlineQueueProvider).drain();
      if (mounted) setState(() => _runs++);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = !_syncing && _runs > 0;
    return IconButton(
      tooltip: 'Reintentar ahora',
      icon: done
          // Key por drenado: cada sincronización terminada vuelve a animar.
          ? AnimatedAppIcon(
              AppIcon.cloudDone,
              key: ValueKey('sync-done-$_runs'),
              state: AppIconState.success,
              excludeFromSemantics: true,
            )
          : AnimatedAppIcon(
              AppIcon.syncing,
              state: _syncing ? AppIconState.loading : AppIconState.idle,
              excludeFromSemantics: true,
            ),
      onPressed: _syncing ? null : _drain,
    );
  }
}

/// Aviso de conectividad sobre la lista de pendientes.
class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          AnimatedAppIcon(
            online ? AppIcon.wifi : AppIcon.wifiOff,
            color: online ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              online
                  ? 'Con señal. Las acciones se suben automáticamente.'
                  : 'Sin señal. Se subirán al recuperar conexión.',
            ),
          ),
        ],
      ),
    );
  }
}
