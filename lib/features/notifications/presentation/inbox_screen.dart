import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/icons/icons.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/paged_search_list.dart';
import '../data/datasources/inbox_remote_data_source.dart';
import 'widgets/inbox_item_card.dart';

export 'widgets/inbox_item_card.dart' show inboxPending, inboxTitle;

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
      ref.invalidate(inboxPreviewProvider);
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
      ref.invalidate(inboxPreviewProvider);
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
        itemBuilder: (context, item) => InboxItemCard(
          item: item,
          read:
              !inboxPending(item) &&
              ((item.read ?? false) || _readHere.contains(item.id ?? '')),
          onTap: () => _markRead(item),
        ),
      ),
    );
  }
}
