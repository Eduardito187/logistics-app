import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/data7.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../controllers/supervisor_controllers.dart';
import 'eta_row.dart';

/// Resumen de ETA por parada, obtenido de `getPlanEta`. Se carga aparte para
/// que un fallo de ETA no tape el detalle del plan.
class EtaSection extends ConsumerWidget {
  const EtaSection({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eta = ref.watch(planEtaProvider(planId));
    return SectionCard(
      title: 'ETA por parada',
      child: AsyncValueView<Data7>(
        value: eta,
        onRetry: () => ref.invalidate(planEtaProvider(planId)),
        data: (data) {
          final stops = [...data.stops]
            ..sort((a, b) => a.sequence.compareTo(b.sequence));
          if (stops.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Sin ETA calculada todavía.'),
            );
          }
          return Column(
            children: [for (final stop in stops) EtaRow(stop: stop)],
          );
        },
      ),
    );
  }
}
