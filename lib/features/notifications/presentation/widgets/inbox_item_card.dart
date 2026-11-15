import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';

/// `true` si el ítem es un pendiente operativo (alerta de flota sin reconocer o
/// documento por vencer): no se marca leído, desaparece al resolverse.
bool inboxPending(StaffInboxItem item) =>
    item.kind == StaffInboxItemKind.alert ||
    item.kind == StaffInboxItemKind.document;

/// Título del ítem. En alertas y documentos el backend manda un CÓDIGO: se
/// muestra legible, sin guiones.
String inboxTitle(StaffInboxItem item) {
  final raw = (item.title ?? '').trim();
  if (!inboxPending(item)) return raw.isEmpty ? 'Aviso' : raw;
  final prefix = item.kind == StaffInboxItemKind.alert
      ? 'Alerta de flota'
      : 'Documento';
  if (raw.isEmpty) return prefix;
  return '$prefix: ${raw.replaceAll('_', ' ').toLowerCase()}';
}

/// Un aviso de la empresa (o un pendiente operativo) en una tarjeta.
class InboxItemCard extends StatelessWidget {
  const InboxItemCard({
    super.key,
    required this.item,
    required this.read,
    this.onTap,
  });

  final StaffInboxItem item;

  /// Ya leído (en el servidor o en esta pantalla).
  final bool read;
  final VoidCallback? onTap;

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = inboxPending(item);
    final sentAt = item.sentAt?.toLocal();
    return SectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inboxTitle(item),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: read ? FontWeight.w600 : FontWeight.w800,
                  ),
                ),
              ),
              if (pending)
                StatusPill(
                  item.kind == StaffInboxItemKind.alert
                      ? 'Alerta'
                      : item.severity == 'expired'
                      ? 'Vencido'
                      : 'Por vencer',
                  tone: item.severity == 'expiring'
                      ? PillTone.warning
                      : PillTone.danger,
                )
              else if (!read)
                const StatusPill('Nuevo', tone: PillTone.info),
            ],
          ),
          if (item.body != null) ...[
            const SizedBox(height: 4),
            Text(item.body!),
          ],
          if (sentAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_two(sentAt.day)}/${_two(sentAt.month)}/${sentAt.year} '
              '${_two(sentAt.hour)}:${_two(sentAt.minute)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
