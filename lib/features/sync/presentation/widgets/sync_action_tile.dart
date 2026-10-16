import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/offline/app_database.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../../../core/widgets/status_pill.dart';

/// Fila de una acción de la cola offline: pendiente (con hora) o fallida (con
/// motivo y botón de reintento manual).
class SyncActionTile extends ConsumerWidget {
  const SyncActionTile({super.key, required this.action});

  final OutboxAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = action.status == 'failed';
    final time = DateFormat('dd/MM HH:mm').format(action.occurredAt);
    return Card(
      child: ListTile(
        leading: Icon(
          failed ? Icons.error : Icons.schedule,
          color: failed ? Colors.red : Colors.blueGrey,
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
