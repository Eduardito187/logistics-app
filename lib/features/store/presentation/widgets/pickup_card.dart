import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import 'shipment_status_pill.dart';

/// ¿El pedido YA está en la tienda para que el cliente lo retire? El chofer lo
/// dejó (`progress.ready_for_pickup_at` con valor) y todavía no se entregó ni
/// se canceló. Es la señal de que el personal de tienda puede entregarlo AHORA
/// (lo demás de la lista sigue en camino).
bool shipmentReadyForPickup(Shipment shipment) =>
    shipment.progress?.readyForPickupAt != null &&
    shipment.status != ShipmentStatus.delivered &&
    shipment.status != ShipmentStatus.cancelled &&
    shipment.status != ShipmentStatus.failed;

/// Hora en que llegó a la tienda, `HH:MM` local, o `null`.
String? pickupArrivedAt(Shipment shipment) {
  final at = shipment.progress?.readyForPickupAt?.toLocal();
  if (at == null) return null;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(at.hour)}:${two(at.minute)}';
}

/// Tarjeta de un envío para entrega en mostrador: lleva al POD al tocarla. Los
/// pedidos que el chofer ya dejó se marcan "Listo para retirar" (verde); los
/// que siguen en camino muestran su estado, más apagados.
class PickupCard extends StatelessWidget {
  const PickupCard({super.key, required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = shipmentReadyForPickup(shipment);
    final arrivedAt = ready ? pickupArrivedAt(shipment) : null;
    return SectionCard(
      onTap: () => context.push('/store/pickup/pod', extra: shipment),
      // El listo para retirar resalta; el que está en camino queda neutro.
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Franja de color a la izquierda: verde = se puede entregar ya.
            // Acompaña el alto del contenido (texto grande en tablet).
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: ready
                    ? AppColors.success
                    : theme.colorScheme.outlineVariant,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.customerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pedido ${shipment.externalId}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (shipment.customerDocumentId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Doc: ${shipment.customerDocumentId}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (ready)
                      _ReadyBadge(arrivedAt: arrivedAt)
                    else
                      ShipmentStatusPill(shipment.status),
                  ],
                ),
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 8),
                child: AnimatedAppIcon(
                  AppIcon.chevronRight,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Listo para retirar · Llegó 10:52" en verde.
class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge({this.arrivedAt});

  final String? arrivedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnimatedAppIcon(
            AppIcon.pickupStore,
            color: AppColors.success,
            size: 16,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              arrivedAt == null
                  ? 'Listo para retirar'
                  : 'Listo para retirar · Llegó $arrivedAt',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
