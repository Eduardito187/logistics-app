import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/theme/app_colors.dart';
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

/// Cuándo se envió, en palabras: "Hoy 18:42", "Ayer 09:10" o la fecha.
String inboxWhen(DateTime sentAt, {DateTime? now}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final local = sentAt.toLocal();
  final today = now ?? DateTime.now();
  final hour = '${two(local.hour)}:${two(local.minute)}';
  final days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(local.year, local.month, local.day)).inDays;
  if (days == 0) return 'Hoy $hour';
  if (days == 1) return 'Ayer $hour';
  return '${two(local.day)}/${two(local.month)}/${local.year} $hour';
}

/// Un aviso de la empresa (o un pendiente operativo) en una tarjeta: ícono
/// del tipo, título, mensaje completo y cuándo llegó. Sin leer se distingue
/// de un vistazo (borde y punto de color, título en negrita).
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pending = inboxPending(item);
    final sentAt = item.sentAt;
    final isAlert = item.kind == StaffInboxItemKind.alert;
    final accent = pending
        ? (item.severity == 'expiring' ? AppColors.warning : scheme.error)
        : scheme.primary;
    final highlighted = pending || !read;
    return Material(
      color: highlighted
          ? accent.withValues(alpha: 0.08)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: highlighted
              ? accent.withValues(alpha: 0.55)
              : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: AnimatedAppIcon(
                  pending
                      ? (isAlert ? AppIcon.incident : AppIcon.badge)
                      : AppIcon.inbox,
                  color: accent,
                  size: 22,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            inboxTitle(item),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: highlighted
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (pending)
                          StatusPill(
                            isAlert
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
                    if (item.body != null && item.body!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(item.body!, style: theme.textTheme.bodyMedium),
                    ],
                    if (sentAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        inboxWhen(sentAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
