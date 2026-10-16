import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/app_database.dart';
import '../offline/offline_queue.dart';
import '../theme/app_colors.dart';

/// Stream de la cola local para la UI (acciones pendientes/fallidas).
final syncQueueProvider = StreamProvider<List<OutboxAction>>(
  (ref) => ref.watch(offlineQueueProvider).watchQueue(),
);

/// Indicador de sincronización para la AppBar: muestra cuántas acciones de
/// terreno están pendientes de subir. Verde cuando todo está sincronizado.
class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(syncQueueProvider).value ?? const [];
    final online = ref.watch(connectivityProvider).value ?? true;
    final pending = queue.where((a) => a.status != 'failed').length;
    final failed = queue.where((a) => a.status == 'failed').length;

    final IconData icon;
    final Color color;
    final String label;
    if (!online) {
      icon = Icons.cloud_off;
      color = AppColors.warning;
      label = pending > 0 ? '$pending' : 'Sin red';
    } else if (failed > 0) {
      icon = Icons.error_outline;
      color = AppColors.danger;
      label = '$failed';
    } else if (pending > 0) {
      icon = Icons.sync;
      color = AppColors.info;
      label = '$pending';
    } else {
      icon = Icons.cloud_done;
      color = AppColors.success;
      label = '';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
