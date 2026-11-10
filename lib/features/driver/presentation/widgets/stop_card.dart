import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../driver_common.dart';
import '../driver_route_status.dart';
import 'delivery_badge.dart';

/// Tarjeta de una parada (versión sin línea de timeline, para la grilla de 2
/// columnas en tablet): marcador con el número de secuencia, cliente,
/// dirección, ETA y badge de estado. Al tocarla abre el detalle.
class StopCard extends StatelessWidget {
  const StopCard({super.key, required this.stop, this.status});

  final DriverRouteStop stop;

  /// Estado a mostrar si difiere del de la parada (resuelta localmente, sin
  /// sincronizar todavía). `null` = el de [stop].
  final DriverRouteStopStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = this.status ?? stop.status;
    final color = stopColor(status);
    final name =
        stop.customerName ?? stop.orderReference ?? 'Parada ${stop.sequence}';

    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => openStopDetail(context, stop),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marcador con el número de secuencia.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${stop.sequence}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (stop.address != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            stop.address!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DeliveryBadge(status: status),
                  if (stop.etaAt != null)
                    Text(
                      'ETA ${formatTime(stop.etaAt!)}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
