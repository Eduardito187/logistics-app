import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/offline_queue.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/sync_badge.dart';
import 'widgets/sync_action_tile.dart';

/// Estado de la cola offline: acciones de terreno pendientes de subir y las que
/// fallaron (datos rechazados), con reintento manual.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(syncQueueProvider);
    final online = ref.watch(connectivityProvider).value ?? true;

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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
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
              ),
              const SizedBox(height: 16),
              for (final action in actions) ...[
                SyncActionTile(action: action),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
      ),
    );
  }
}
