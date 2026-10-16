import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/notification_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/notification_labels.dart';

/// Fila de la bandeja: tipo de mensaje, envío de referencia y estado. Abre el
/// detalle de la notificación al tocarla.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification});

  final NotificationView notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference =
        notification.shipmentExternalId ?? notification.shipmentId;

    return SectionCard(
      onTap: () => context.push('/notifications/${notification.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.messageType.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Envío $reference',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 10),
                StatusPill(
                  notification.status.label,
                  tone: notification.status.tone,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        ],
      ),
    );
  }
}
