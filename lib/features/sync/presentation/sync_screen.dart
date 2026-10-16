import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/responsive_body.dart';
import '../../../core/offline/offline_queue.dart';
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
        actions: [
          IconButton(
            tooltip: 'Reintentar ahora',
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(offlineQueueProvider).drain(),
          ),
        ],
      ),
      body: queue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'No se pudo leer la cola',
          message: '$e',
        ),
        data: (actions) {
          if (actions.isEmpty) {
            return const EmptyState(
              icon: Icons.cloud_done,
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
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        SyncActionTile(action: actions[i]),
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

/// Aviso de conectividad sobre la lista de pendientes.
class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Icon(
            online ? Icons.wifi : Icons.wifi_off,
            color: online ? Colors.green : Colors.orange,
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
