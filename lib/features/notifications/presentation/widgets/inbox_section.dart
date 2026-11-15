import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/export.dart';
import '../../data/datasources/inbox_remote_data_source.dart';
import 'inbox_item_card.dart';

/// Avisos de la empresa DENTRO de la pantalla de notificaciones: son una
/// notificación más. Muestra los más recientes; "Ver todos" abre la bandeja
/// completa. Sin avisos no ocupa lugar.
class InboxSection extends ConsumerStatefulWidget {
  const InboxSection({super.key});

  /// Cuántos avisos se muestran acá (el resto, en "Ver todos").
  static const int previewCount = 5;

  @override
  ConsumerState<InboxSection> createState() => _InboxSectionState();
}

class _InboxSectionState extends ConsumerState<InboxSection> {
  /// Leídos acá: se ven como leídos sin esperar la recarga.
  final Set<String> _readHere = <String>{};

  Future<void> _markRead(StaffInboxItem item) async {
    final id = item.id;
    if (inboxPending(item)) return;
    if (id == null || (item.read ?? false) || _readHere.contains(id)) return;
    setState(() => _readHere.add(id));
    try {
      await ref.read(inboxRemoteDataSourceProvider).markRead(id);
      ref.invalidate(inboxUnreadCountProvider);
    } on Object {
      if (mounted) setState(() => _readHere.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(inboxPreviewProvider).value;
    final items = page?.items ?? const <StaffInboxItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final shown = items.take(InboxSection.previewCount).toList();
    final more = items.length > shown.length || (page?.hasMore ?? false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Avisos de la empresa',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final item in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InboxItemCard(
                key: ValueKey(item.id),
                item: item,
                read:
                    !inboxPending(item) &&
                    ((item.read ?? false) || _readHere.contains(item.id ?? '')),
                onTap: () => _markRead(item),
              ),
            ),
          if (more)
            TextButton(
              onPressed: () async {
                await context.push('/inbox');
                ref.invalidate(inboxPreviewProvider);
                ref.invalidate(inboxUnreadCountProvider);
              },
              child: const Text('Ver todos los avisos'),
            ),
        ],
      ),
    );
  }
}
