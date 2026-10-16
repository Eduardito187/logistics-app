import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/driver_controllers.dart';
import 'info_row.dart';

/// Estado detallado de la entrega del envío (status real + escaneos), leído del
/// backend. Complementa el estado de la parada con lo que ya se registró.
class DeliveryStateCard extends ConsumerWidget {
  const DeliveryStateCard({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryStateProvider(shipmentId));
    return SectionCard(
      title: 'Estado de la entrega',
      child: AsyncValueView<Delivery>(
        value: state,
        onRetry: () => ref.invalidate(deliveryStateProvider(shipmentId)),
        data: (delivery) {
          final reason = delivery.failureReason;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(
                _deliveryStatusLabel(delivery.status),
                tone: _deliveryStatusTone(delivery.status),
              ),
              const SizedBox(height: 8),
              InfoRow(
                icon: Icons.qr_code_scanner,
                text: '${delivery.scans.length} escaneo(s) registrados',
              ),
              if (delivery.podConfirmation != null)
                InfoRow(
                  icon: Icons.verified,
                  text: 'Confirmación: ${delivery.podConfirmation!}',
                ),
              if (reason != null)
                InfoRow(
                  icon: Icons.error_outline,
                  text: 'Motivo de falla: ${_failureReasonLabel(reason)}',
                ),
            ],
          );
        },
      ),
    );
  }
}

String _deliveryStatusLabel(DeliveryStatus status) => switch (status) {
  DeliveryStatus.pending => 'Pendiente',
  DeliveryStatus.prepared => 'Preparada',
  DeliveryStatus.loaded => 'Cargada',
  DeliveryStatus.inTransit => 'En tránsito',
  DeliveryStatus.delivered => 'Entregada',
  DeliveryStatus.failed => 'Fallida',
  _ => 'Desconocido',
};

PillTone _deliveryStatusTone(DeliveryStatus status) => switch (status) {
  DeliveryStatus.delivered => PillTone.success,
  DeliveryStatus.failed => PillTone.danger,
  DeliveryStatus.inTransit => PillTone.info,
  _ => PillTone.neutral,
};

String _failureReasonLabel(FailureReason reason) => switch (reason) {
  FailureReason.customerAbsent => 'Cliente ausente',
  FailureReason.wrongAddress => 'Dirección incorrecta',
  FailureReason.rejected => 'Pedido rechazado',
  FailureReason.damaged => 'Producto dañado',
  FailureReason.other => 'Otro motivo',
  _ => 'Motivo desconocido',
};
