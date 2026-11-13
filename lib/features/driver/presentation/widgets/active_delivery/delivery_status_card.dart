import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/export.dart';
import '../../../../../core/icons/icons.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/route_navigation.dart';
import '../../../domain/route_progress.dart';

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
    required this.progress,
    this.remaining,
  });

  final DriverRoute route;
  final DriverRouteStop stop;

  /// Avance de la ruta calculado item por item (fuente única); de acá sale el
  /// "de M" y la barra de progreso, para no contradecir al resto de la app.
  final RouteProgress progress;

  /// Estimación en vivo hasta la parada; `null` sin posición del camión.
  final RemainingEstimate? remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Total, posición y barra de la MISMA fuente (RouteProgress item por item):
    // así "de M", el ordinal y el relleno NUNCA se contradicen (antes el total
    // salía de route.totalStops y el avance de las paradas listadas → si el
    // backend mandaba distinto, divergían, justo lo que RouteProgress evita).
    final total = progress.total > 0 ? progress.total : route.stops.length;
    // "Parada N de M": N = ordinal de ESTA entrega en el avance del día
    // (atendidas + 1), NO la secuencia de la parada. Con entregas fuera de orden
    // la secuencia confunde ("Parada 1 de 7" con 6 ya hechas): el chofer va en
    // la 7ª. Coincide con el contador de la isla (6/7 hechas → vas en la 7).
    final position = total == 0 ? 1 : (progress.attended + 1).clamp(1, total);
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
              'Parada $position de $total',
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
                AnimatedAppIcon(
                  AppIcon.deliver,
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
              completed: progress.attended.clamp(0, total),
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

/// Metros a la parada por debajo de los cuales se considera que el camión YA
/// llegó (geocerca): a esa distancia el GPS urbano no distingue mejor y mostrar
/// "Faltan 30 m" confunde. Se muestra "Llegaste a destino".
const double kArrivalMeters = 60;

/// `true` si el camión está prácticamente en la parada (dentro de la geocerca y
/// sin estar fuera de ruta).
bool arrivedAtStop(RemainingEstimate estimate) =>
    !estimate.offRoute && estimate.meters <= kArrivalMeters;

/// "Faltan 4,2 km · 12 min" (o "Llegaste a destino" al entrar en la geocerca) y,
/// si corresponde, la pastilla "Fuera de ruta".
class _RemainingRow extends StatelessWidget {
  const _RemainingRow({required this.estimate});

  final RemainingEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arrived = arrivedAtStop(estimate);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (arrived)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedAppIcon(
                AppIcon.place,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Llegaste a destino',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          )
        else
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
                const AnimatedAppIcon(
                  AppIcon.plans,
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
    final reduce = MediaQuery.disableAnimationsOf(context);
    final target = (completed / total).clamp(0.0, 1.0).toDouble();
    // El avance se ANIMA hacia su nuevo valor (antes saltaba de golpe al cerrar
    // una entrega). TweenAnimationBuilder interpola desde el valor anterior al
    // nuevo en cada reconstrucción.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduce ? target : 0.0, end: target),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        if (total > 12) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: done,
              backgroundColor: todo,
            ),
          );
        }
        // Barra en tramos: la fracción animada (0..total) llena cada tramo de
        // izquierda a derecha, con el último tramo pintándose parcialmente.
        final filled = value * total;
        return Semantics(
          label: '$completed de $total paradas atendidas',
          child: Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _SegmentBar(
                    // Cuánto de ESTE tramo está lleno (0..1).
                    fill: (filled - i).clamp(0.0, 1.0).toDouble(),
                    done: done,
                    todo: todo,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Un tramo de la barra de progreso: fondo "por hacer" y, encima, un relleno
/// "hecho" cuya fracción [fill] (0..1) permite animar el llenado tramo a tramo.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.fill,
    required this.done,
    required this.todo,
  });

  final double fill;
  final Color done;
  final Color todo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(height: 8, color: todo),
          FractionallySizedBox(
            widthFactor: fill,
            child: Container(height: 8, color: done),
          ),
        ],
      ),
    );
  }
}
