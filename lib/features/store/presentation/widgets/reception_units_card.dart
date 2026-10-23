import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/shelf_locations_notifier.dart';
import '../short_unit_id.dart';

/// Lista de bultos del manifiesto con su estado y la ubicación en estante.
class ReceptionUnitsCard extends ConsumerWidget {
  const ReceptionUnitsCard({
    super.key,
    required this.expected,
    required this.received,
    required this.surplus,
  });

  final List<String> expected;
  final Set<String> received;
  final Set<String> surplus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelves = ref.watch(shelfLocationsProvider);
    final rows = <Widget>[];
    for (final id in expected) {
      rows.add(
        _unitRow(context, id, received.contains(id), false, shelves[id]),
      );
    }
    for (final id in surplus) {
      rows.add(_unitRow(context, id, true, true, shelves[id]));
    }
    return SectionCard(
      title: 'Bultos',
      child: Column(children: rows),
    );
  }

  Widget _unitRow(
    BuildContext context,
    String unitId,
    bool isReceived,
    bool isSurplus,
    String? shelf,
  ) {
    final theme = Theme.of(context);
    final (String text, PillTone tone, IconData icon) = isSurplus
        ? ('Sobrante', PillTone.danger, Icons.report_gmailerrorred)
        : isReceived
        ? ('Recibido', PillTone.success, Icons.check_circle)
        : ('Pendiente', PillTone.neutral, Icons.radio_button_unchecked);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulto ${shortUnitId(unitId)}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (shelf != null)
                  Text(
                    'Estante: $shelf',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          StatusPill(text, tone: tone, icon: icon),
        ],
      ),
    );
  }
}
