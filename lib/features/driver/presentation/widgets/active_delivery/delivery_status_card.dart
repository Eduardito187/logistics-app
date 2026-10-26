import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/route_navigation.dart';

final DateFormat _hour = DateFormat.Hm('es');

/// Tarjeta superior: avance de la ruta (parada N de M en tramos), hora estimada
/// de llegada, lo que falta (distancia y tiempo estimados con la posición en
/// vivo), un aviso discreto si el camión se salió del trazo y a quién se lleva
/// la entrega.
class DeliveryStatusCard extends StatelessWidget {
  const DeliveryStatusCard({
    super.key,
    required this.route,
    required this.stop,
    this.remaining,
  });

  final DriverRoute route;
  final DriverRouteStop stop;

  /// Estimación en vivo hasta la parada; `null` sin posición del camión.
  final RemainingEstimate? remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = route.totalStops > 0 ? route.totalStops : route.stops.length;
    final eta = stop.etaAt;
    final customer = stop.customerName ?? 'el cliente';

    return Material(
      color: theme.colorScheme.surface,
      elevation: 3,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parada ${stop.sequence} de $total',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    eta == null
                        ? 'Sin hora estimada'
                        : 'Llegada ${_hour.format(eta.toLocal())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.local_shipping,
                  size: 32,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ),
            if (remaining != null) ...[
              const SizedBox(height: 4),
              _RemainingRow(estimate: remaining!),
            ],
            const SizedBox(height: 10),
            RouteProgressBar(
              total: total,
              completed: route.completedStops.clamp(0, total),
            ),
            const SizedBox(height: 10),
            Text(
              'En camino a $customer',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Faltan 4,2 km · 12 min" y, si corresponde, la pastilla "Fuera de ruta".
class _RemainingRow extends StatelessWidget {
  const _RemainingRow({required this.estimate});

  final RemainingEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Faltan ${formatDistance(estimate.meters)} · '
          '${formatRemainingTime(estimate.duration)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (estimate.offRoute)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.alt_route,
                  size: 16,
                  color: AppColors.hcWarning,
                ),
                const SizedBox(width: 4),
                Text(
                  'Fuera de ruta',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.hcWarning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Barra de progreso en tramos (uno por parada), como en las apps de delivery.
/// Con muchas paradas cae a una barra continua para no dibujar tramos de 2 px.
class RouteProgressBar extends StatelessWidget {
  const RouteProgressBar({
    super.key,
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = scheme.onSurface;
    final todo = scheme.surfaceContainerHighest;
    if (total <= 0) {
      return const SizedBox(height: 8);
    }
    if (total > 12) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: completed / total,
          minHeight: 8,
          color: done,
          backgroundColor: todo,
        ),
      );
    }
    return Semantics(
      label: '$completed de $total paradas atendidas',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: i < completed ? done : todo,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
