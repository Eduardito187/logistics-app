import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/offline/app_database.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';

/// Fila de una acción de la cola offline: pendiente (con hora) o fallida (con
/// motivo y botón de reintento manual).
/// Formato de hora compartido (se crea una sola vez, no en cada build).
final DateFormat _timeFormat = DateFormat('dd/MM HH:mm');

class SyncActionTile extends ConsumerWidget {
  const SyncActionTile({super.key, required this.action});

  final OutboxAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = action.status == 'failed';
    final time = _timeFormat.format(action.occurredAt);
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          failed ? Icons.error : Icons.schedule,
          color: failed ? AppColors.danger : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(action.label ?? action.kind),
        subtitle: Text(
          failed ? (action.lastError ?? 'Rechazada') : 'En cola · $time',
        ),
        trailing: failed
            ? TextButton(
                onPressed: () =>
                    ref.read(offlineQueueProvider).retryFailed(action.id),
                child: const Text('Reintentar'),
              )
            : const StatusPill('Pendiente', tone: PillTone.info),
      ),
    );
  }
}
