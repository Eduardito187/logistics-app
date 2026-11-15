import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/datasources/inbox_remote_data_source.dart';

/// Acceso a "Avisos de la empresa" con la cantidad sin leer.
class InboxEntryCard extends ConsumerWidget {
  const InboxEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadCountProvider).value ?? 0;
    return SectionCard(
      onTap: () async {
        await context.push('/inbox');
        // Al volver, los leídos ya no cuentan.
        ref.invalidate(inboxUnreadCountProvider);
      },
      child: Row(
        children: [
          const AnimatedAppIcon(AppIcon.inbox, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Avisos de la empresa',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          if (unread > 0)
            StatusPill(
              unread == 1 ? '1 nuevo' : '$unread nuevos',
              tone: PillTone.info,
            ),
          const SizedBox(width: 4),
          const AnimatedAppIcon(
            AppIcon.chevronRight,
            excludeFromSemantics: true,
          ),
        ],
      ),
    );
  }
}
