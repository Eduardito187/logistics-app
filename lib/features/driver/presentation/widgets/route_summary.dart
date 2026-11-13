import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/route_progress.dart';
import '../controllers/locally_settled_stops.dart';
import '../driver_route_status.dart';

/// Resumen de avance de la ruta: un anillo de progreso con gradiente de marca
/// (entregadas/total), los conteos (entregadas / fallidas / por hacer) y el
/// badge del estado general. Estilo DisTrack.
///
/// El avance se calcula ITEM POR ITEM con [RouteProgress] (estado efectivo de
/// cada parada, incluyendo lo resuelto en este teléfono), nunca con los
/// conteos agregados del backend: así el anillo coincide SIEMPRE con la lista de
/// paradas y con la detección de "ruta completada" (antes el resumen decía 5/7
/// y la lista mostraba 6 entregadas).
class RouteSummary extends ConsumerWidget {
  const RouteSummary({super.key, required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settled = ref.watch(locallySettledStopsProvider);
    final progress = RouteProgress.of(route, settled);
    final total = progress.total;
    final completed = progress.delivered;
    final remaining = progress.pending;
    final failed = progress.failed;
    // El anillo refleja las ENTREGADAS (coincide con el número del centro
    // "X/Y listas"); el estado "completada" se decide por [isComplete] (sin
    // paradas pendientes), no por el conteo del backend.
    final double fraction = total > 0
        ? (completed / total).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Anillo de progreso con el conteo al centro.
          SizedBox(
            width: 76,
            height: 76,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: reduce ? fraction : 0.0,
                end: fraction,
              ),
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CustomPaint(
                painter: _ProgressRingPainter(
                  fraction: value,
                  track: scheme.onSurface.withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completed/$total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      Text(
                        'listas',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusPill(
                    // "Completada" se decide item por item (sin pendientes), no
                    // por `route.status` del backend (podía decirlo de más con
                    // una parada fallida/reprogramada).
                    progress.isComplete
                        ? 'Completada'
                        : progress.attended > 0
                        ? 'En curso'
                        : routeStatusLabel(route.status),
                    tone: progress.isComplete ? PillTone.success : PillTone.info,
                  ),
                ),
                const SizedBox(height: 10),
                _CountRow(
                  color: AppColors.success,
                  text: '$completed entregadas',
                ),
                if (failed > 0) ...[
                  const SizedBox(height: 4),
                  _CountRow(
                    color: AppColors.danger,
                    text: '$failed no entregadas',
                  ),
                ],
                const SizedBox(height: 4),
                _CountRow(
                  color: AppColors.accent,
                  text: '$remaining por hacer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de conteo: punto de color + texto.
class _CountRow extends StatelessWidget {
  const _CountRow({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dibuja el anillo: pista tenue + arco de progreso con gradiente de marca
/// (rojo → ámbar), arrancando arriba y con extremos redondeados.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({required this.fraction, required this.track});

  final double fraction;
  final Color track;

  static const double _stroke = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - _stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [
          AppColors.brand,
          AppColors.brandDark,
          AppColors.accent,
          AppColors.brand,
        ],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(arcRect);
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.fraction != fraction || old.track != track;
}
