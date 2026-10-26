import 'package:flutter/material.dart';

import '../../../../core/api/models/settlement.dart';
import '../../../../core/api/models/settlement_status.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_loader.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import 'settlement_detail_row.dart';
import 'settlement_format.dart';

/// Detalle de una liquidación con las acciones aprobar / disputar / pagar según
/// el estado. Las acciones se delegan a los callbacks del padre.
class SettlementDetail extends StatelessWidget {
  const SettlementDetail({
    super.key,
    required this.settlement,
    required this.busy,
    required this.onApprove,
    required this.onDispute,
    required this.onPay,
  });

  final Settlement settlement;
  final bool busy;
  final Future<void> Function() onApprove;
  final Future<void> Function() onDispute;
  final Future<void> Function() onPay;

  @override
  Widget build(BuildContext context) {
    final canApprove =
        settlement.status == SettlementStatus.submitted ||
        settlement.status == SettlementStatus.disputed;
    final canDispute = settlement.status == SettlementStatus.submitted;
    final canPay = settlement.status == SettlementStatus.approved;

    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${settlement.corridorFrom} → ${settlement.corridorTo}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    StatusPill(
                      settlementStatusLabel(settlement.status),
                      tone: settlementStatusTone(settlement.status),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  formatCents(settlement.amountCents, settlement.currency),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SettlementDetailRow(label: 'Periodo', value: settlement.period),
                SettlementDetailRow(
                  label: 'Referencia',
                  value: settlement.reference,
                  mono: true,
                ),
                if (settlement.carrierName != null)
                  SettlementDetailRow(
                    label: 'Transportista',
                    value: settlement.carrierName!,
                  ),
                if (settlement.disputeReason != null)
                  SettlementDetailRow(
                    label: 'Motivo de disputa',
                    value: settlement.disputeReason!,
                  ),
                if (settlement.paymentReference != null)
                  SettlementDetailRow(
                    label: 'Referencia de pago',
                    value: settlement.paymentReference!,
                    mono: true,
                  ),
                SettlementDetailRow(
                  label: 'Documentos',
                  value: '${settlement.documents.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (busy)
            // Spinner de pantalla (no de botón): isotipo de marca con pulso.
            const Center(
              child: Padding(padding: EdgeInsets.all(16), child: BrandLoader()),
            )
          else ...[
            if (canApprove)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Aprobar'),
                  ),
                ),
              ),
            if (canPay)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onPay,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Marcar como pagada'),
                  ),
                ),
              ),
            if (canDispute)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDispute,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('Disputar'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
