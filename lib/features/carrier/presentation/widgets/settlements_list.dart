import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/carrier.dart';
import '../../../../core/api/models/settlement.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/carrier_controllers.dart';
import 'settlement_format.dart';

/// Lista de liquidaciones del transportista indicado, con pull-to-refresh.
class SettlementsList extends ConsumerWidget {
  const SettlementsList({super.key, required this.carrier});

  final Carrier carrier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlements = ref.watch(carrierSettlementsProvider(carrier.id));
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(carrierSettlementsProvider(carrier.id)),
      child: AsyncValueView<List<Settlement>>(
        value: settlements,
        onRetry: () => ref.invalidate(carrierSettlementsProvider(carrier.id)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long,
              title: 'Sin liquidaciones',
              message: 'Aquí verás las liquidaciones de tus corredores.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final settlement = list[index];
              return SectionCard(
                onTap: () =>
                    context.push('/carrier/settlements/${settlement.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${settlement.corridorFrom} → ${settlement.corridorTo}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        StatusPill(
                          settlementStatusLabel(settlement.status),
                          tone: settlementStatusTone(settlement.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Periodo ${settlement.period}'),
                    const SizedBox(height: 8),
                    Text(
                      formatCents(settlement.amountCents, settlement.currency),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
