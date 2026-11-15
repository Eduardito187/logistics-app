import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/delivery_mode.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/shipment_delivery_evidence.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/product_thumb.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../picking/domain/usecases/assign_order_vehicle.dart';
import '../../../picking/presentation/widgets/shipment_status_pill.dart';
import '../staff_labels.dart';
import 'staff_pickers.dart';

/// Abre el detalle de un envío (cliente, destino y productos).
Future<void> showShipmentDetailSheet(BuildContext context, Shipment shipment) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ShipmentDetailSheet(shipment: shipment),
    );

/// Detalle de un envío para el administrador: quién lo recibe, dónde y qué
/// lleva (con lo que ya trajo la lista, sin otra llamada) y sus acciones:
/// **asignarlo a un camión** (lo suma a la ruta de ese camión) y
/// **reprogramarlo**. Un pedido cerrado (entregado, fallido, cancelado) no las
/// ofrece.
class ShipmentDetailSheet extends ConsumerStatefulWidget {
  const ShipmentDetailSheet({super.key, required this.shipment});

  final Shipment shipment;

  @override
  ConsumerState<ShipmentDetailSheet> createState() =>
      _ShipmentDetailSheetState();
}

class _ShipmentDetailSheetState extends ConsumerState<ShipmentDetailSheet> {
  bool _busy = false;

  Shipment get shipment => widget.shipment;

  bool get _open =>
      shipment.status == ShipmentStatus.received ||
      shipment.status == ShipmentStatus.planned ||
      shipment.status == ShipmentStatus.inExecution;

  /// Asigna el pedido a un camión: abre su entrega y suma la parada a la ruta
  /// de ese camión (el mismo camino que usa el preparador).
  Future<void> _assignVehicle() async {
    final vehicle = await showVehiclePickerSheet(context);
    if (vehicle == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(assignOrderVehicleProvider)
          .call(shipment.externalId, vehicle.id);
      if (!mounted) return;
      showSuccessSnack(
        context,
        'Pedido asignado al camión ${vehicle.displayPlate}.',
      );
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reschedule() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(
      '/admin/reschedule',
      extra: (shipmentId: shipment.id, orderNumber: shipment.externalId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final reference = shipment.addressReference;
    final delivered = shipment.status == ShipmentStatus.delivered;
    final deliveredAt = shipment.progress?.deliveredAt;
    // La hoja mide lo que mide su contenido (sin aire abajo); si el pedido
    // es largo, llega hasta el 90% de la pantalla y se desplaza.
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pedido ${shipment.externalId}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ShipmentStatusPill(shipment.status),
              ),
              if (delivered) ...[
                const SizedBox(height: 8),
                if (deliveredAt != null)
                  Text('Entregado el ${staffDateTime(deliveredAt)}'),
                const SizedBox(height: 8),
                _EvidenceTags(evidence: shipment.deliveryEvidence),
              ],
              if (_open) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _assignVehicle,
                  icon: AnimatedAppIcon(
                    AppIcon.deliver,
                    state: _busy ? AppIconState.loading : AppIconState.idle,
                    excludeFromSemantics: true,
                  ),
                  label: const Text('Asignar a un camión'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _reschedule,
                  icon: const AnimatedAppIcon(
                    AppIcon.swap,
                    excludeFromSemantics: true,
                  ),
                  label: const Text('Reprogramar'),
                ),
              ],
              const SizedBox(height: 16),
              Text('Cliente', style: muted),
              Text(
                shipment.customerName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (shipment.customerDocumentId != null)
                Text('Documento: ${shipment.customerDocumentId}'),
              if (shipment.customerPhone != null)
                Text('Teléfono: ${shipment.customerPhone}'),
              const SizedBox(height: 16),
              Text(_destinationLabel(shipment.deliveryMode), style: muted),
              Text(shipment.addressText),
              if (reference != null && reference.isNotEmpty)
                Text('Referencia: $reference', style: muted),
              const SizedBox(height: 16),
              Text('Productos', style: muted),
              for (final line in shipment.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      ProductThumb(imageUrl: line.imageUrl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.productName,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(line.sku, style: muted),
                          ],
                        ),
                      ),
                      Text(
                        'x${line.quantity}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Título de la sección de destino según cómo se entrega el pedido.
  static String _destinationLabel(DeliveryMode? deliveryMode) =>
      switch (deliveryMode) {
        DeliveryMode.storePickup => 'Destino · el cliente retira en tienda',
        DeliveryMode.transfer => 'Destino · traslado a tienda',
        _ => 'Destino · entrega a domicilio',
      };
}

/// Cómo se entregó: una etiqueta por cada evidencia que quedó registrada.
class _EvidenceTags extends StatelessWidget {
  const _EvidenceTags({required this.evidence});

  final ShipmentDeliveryEvidence? evidence;

  @override
  Widget build(BuildContext context) {
    final evidence = this.evidence;
    if (evidence == null) return const SizedBox.shrink();
    final tags = [
      if (evidence.signature) ('Firma digital', AppIcon.signature),
      if (evidence.photo) ('Foto de entrega', AppIcon.capture),
      if (evidence.document) ('Foto de documento', AppIcon.badge),
    ];
    if (tags.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: StatusPill('Sin evidencia registrada'),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, icon) in tags)
          StatusPill(label, tone: PillTone.success, icon: icon),
      ],
    );
  }
}
