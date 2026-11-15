import 'package:flutter/material.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/labels/label_lookup.dart';

/// Muestra de qué pedido es la etiqueta escaneada y a qué cliente se entrega.
/// Devuelve `true` si el personal tocó "Entregar este pedido".
Future<bool?> showPickupLabelSheet(
  BuildContext context, {
  required PickupLabelInfo info,
  required Shipment? shipment,
}) => showModalBottomSheet<bool>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => PickupLabelSheet(info: info, shipment: shipment),
);

/// Hoja con los datos de la etiqueta: pedido, producto y, si el pedido es un
/// recojo de esta tienda ([shipment]), los datos del cliente y el acceso a su
/// entrega.
class PickupLabelSheet extends StatelessWidget {
  const PickupLabelSheet({
    super.key,
    required this.info,
    required this.shipment,
  });

  final PickupLabelInfo info;

  /// Recojo de esta tienda al que pertenece la etiqueta, o `null` si no figura.
  final Shipment? shipment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shipment = this.shipment;
    final order = shipment?.externalId ?? info.orderNumber;
    final sku = info.sku;
    // Nombre del producto: el de la etiqueta o, por SKU, el de la línea del
    // pedido (el QR solo trae el SKU).
    final productName =
        info.productName ??
        shipment?.lines
            .where((line) => line.sku == sku)
            .map((line) => line.productName)
            .firstOrNull;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              order == null ? 'Etiqueta leída' : 'Pedido $order',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (productName != null || sku != null) ...[
              const SizedBox(height: 12),
              Text('Producto', style: muted),
              if (productName != null)
                Text(
                  productName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (sku != null) Text('SKU $sku'),
            ],
            const SizedBox(height: 12),
            if (shipment != null) ...[
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
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const AnimatedAppIcon(
                    AppIcon.pickupStore,
                    excludeFromSemantics: true,
                  ),
                  label: const Text('Entregar este pedido'),
                ),
              ),
            ] else ...[
              // No está entre los recojos cargados: igual se muestra a quién
              // pertenece si el backend lo informó con la etiqueta.
              if (info.customerName != null) ...[
                Text('Cliente', style: muted),
                Text(
                  info.customerName!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (info.customerDocumentId != null)
                  Text('Documento: ${info.customerDocumentId}'),
                if (info.customerPhone != null)
                  Text('Teléfono: ${info.customerPhone}'),
                const SizedBox(height: 12),
              ],
              Text(
                'Este pedido no figura entre los recojos de tu tienda.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
