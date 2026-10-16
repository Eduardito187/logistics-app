import 'package:flutter/material.dart';

import '../../../../core/api/models/shipment_status.dart';
import '../../../../core/widgets/status_pill.dart';

/// Chip de estado del pedido en español con color semántico.
class ShipmentStatusPill extends StatelessWidget {
  const ShipmentStatusPill(this.status, {super.key});

  final ShipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, PillTone tone) = switch (status) {
      ShipmentStatus.received => ('Por preparar', PillTone.info),
      ShipmentStatus.planned => ('Planificado', PillTone.warning),
      ShipmentStatus.inExecution => ('En ejecución', PillTone.warning),
      ShipmentStatus.delivered => ('Entregado', PillTone.success),
      ShipmentStatus.failed => ('Fallido', PillTone.danger),
      ShipmentStatus.cancelled => ('Cancelado', PillTone.neutral),
      ShipmentStatus.$unknown => ('Desconocido', PillTone.neutral),
    };
    return StatusPill(label, tone: tone);
  }
}
