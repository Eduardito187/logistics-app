import 'package:flutter/material.dart';

import '../../../../core/api/models/notification_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/notification_labels.dart';
import 'notification_field.dart';

/// Cuerpo del detalle de una notificación: resumen (tipo, estado, envío, canal
/// actual), la cascada de canales con sus intentos y, si está en cola, el botón
/// para suprimirla.
class NotificationDetailBody extends StatelessWidget {
  const NotificationDetailBody({
    super.key,
    required this.notification,
    required this.suppressing,
    required this.onSuppress,
  });

  final NotificationView notification;
  final bool suppressing;
  final Future<void> Function() onSuppress;

  @override
  Widget build(BuildContext context) {
    final reference =
        notification.shipmentExternalId ?? notification.shipmentId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Resumen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationField(
                label: 'Tipo',
                value: notification.messageType.label,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Estado',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  StatusPill(
                    notification.status.label,
                    tone: notification.status.tone,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              NotificationField(label: 'Envío', value: reference),
              const SizedBox(height: 12),
              NotificationField(
                label: 'Canal actual',
                value: notification.currentChannel.label,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Cascada de canales',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final channel in notification.channels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NotificationField(
                    label: channel.label,
                    value:
                        '${notification.attempts[channel.json] ?? 0} intento(s)',
                  ),
                ),
              if (notification.channels.isEmpty)
                Text(
                  'Sin canales configurados.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        if (notification.status.canSuppress) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: suppressing ? null : () => onSuppress(),
            icon: suppressing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.block),
            label: const Text('Suprimir notificación'),
          ),
        ],
      ],
    );
  }
}
