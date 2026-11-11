import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/icons/icons.dart';

import '../../../../core/api/export.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/driver_controllers.dart';
import 'info_row.dart';

/// Estado detallado de la entrega del envío (status real + escaneos), leído del
/// backend. Complementa el estado de la parada con lo que ya se registró.
///
/// Es información COMPLEMENTARIA: una parada pendiente todavía no tiene actividad
/// de entrega y el backend puede no devolver nada. En ese caso (o si no se pudo
/// leer) se muestra un estado neutro "Sin movimientos…", NUNCA un error con
/// "Reintentar": no es una falla que el chofer deba resolver en terreno.
class DeliveryStateCard extends ConsumerWidget {
  const DeliveryStateCard({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryStateProvider(shipmentId));
    return SectionCard(
      title: 'Estado de la entrega',
      child: state.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        // Sin datos aún (o no se pudo leer): neutro, sin alarmar.
        error: (_, _) => const InfoRow(
          icon: AppIcon.pending,
          text: 'Sin movimientos registrados todavía.',
        ),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: InfoRow(icon: AppIcon.pending, text: 'Cargando…'),
        ),
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
                icon: AppIcon.scan,
                text: '${delivery.scans.length} escaneo(s) registrados',
              ),
              if (delivery.podConfirmation != null)
                InfoRow(
                  icon: AppIcon.verified,
                  text: 'Confirmación: ${delivery.podConfirmation!}',
                ),
              if (reason != null)
                InfoRow(
                  icon: AppIcon.error,
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
