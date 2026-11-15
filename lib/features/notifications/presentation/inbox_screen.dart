import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/paged_search_list.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/datasources/inbox_remote_data_source.dart';

/// Avisos de la empresa para el usuario: lo que el administrador envió a su
/// rol, a su tienda o a él. Tocar un aviso lo marca como leído.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final GlobalKey<PagedSearchListState<StaffInboxItem>> _list = GlobalKey();

  /// Leídos en esta pantalla: se ven como leídos sin volver a pedir la lista.
  final Set<String> _readHere = <String>{};

  Future<void> _markRead(StaffInboxItem item) async {
    final id = item.id;
    // Solo los AVISOS se marcan como leídos. Las alertas de flota y los
    // documentos por vencer no: desaparecen solos cuando se resuelven.
    if (inboxPending(item)) return;
    if (id == null || (item.read ?? false) || _readHere.contains(id)) return;
    setState(() => _readHere.add(id));
    try {
      await ref.read(inboxRemoteDataSourceProvider).markRead(id);
      ref.invalidate(inboxUnreadCountProvider);
    } on Object {
      // Sin señal: se intenta de nuevo la próxima vez que lo abra.
      if (mounted) setState(() => _readHere.remove(id));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(inboxRemoteDataSourceProvider).markAllRead();
      if (!mounted) return;
      ref.invalidate(inboxUnreadCountProvider);
      unawaited(_list.currentState?.reload());
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos de la empresa'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Marcar leídos'),
          ),
        ],
      ),
      body: PagedSearchList<StaffInboxItem>(
        key: _list,
        showSearch: false,
        emptyTitle: 'Sin avisos',
        emptyIcon: AppIcon.inbox,
        fetch: (_, page) => ref.read(inboxRemoteDataSourceProvider).list(page),
        itemBuilder: (context, item) {
          final theme = Theme.of(context);
          final pending = inboxPending(item);
          final read =
              !pending &&
              ((item.read ?? false) || _readHere.contains(item.id ?? ''));
          final sentAt = item.sentAt?.toLocal();
          return SectionCard(
            onTap: () => _markRead(item),
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
        },
      ),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

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
