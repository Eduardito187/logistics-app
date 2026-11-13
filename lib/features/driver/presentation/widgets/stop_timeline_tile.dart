import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../driver_common.dart';
import '../driver_route_status.dart';
import 'delivery_badge.dart';

/// Animación de entrada escalonada (fade + deslizar hacia arriba) para cada
/// ítem de la lista de paradas, estilo app de tracking. El desfase crece con el
/// índice pero se topa a los primeros ítems: una lista larga no espera segundos
/// a que aparezcan las paradas de abajo. SOLO animación de entrada, sin loops.
/// Respeta "reducir movimiento": ahí muestra el hijo de una vez.
class StopEntrance extends StatefulWidget {
  const StopEntrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StopEntrance> createState() => _StopEntranceState();
}

class _StopEntranceState extends State<StopEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    // Desfase de ~40 ms por tarjeta, topado para que lo que entra al hacer
    // scroll aparezca casi al instante.
    final steps = widget.index.clamp(0, 10);
    Future<void>.delayed(Duration(milliseconds: 40 * steps), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Nodo del timeline vertical de la ruta: a la izquierda el marcador (círculo
/// con el número de secuencia, o el ícono animado del estado cuando la parada
/// ya se resolvió) unido por una línea vertical al siguiente; a la derecha la
/// tarjeta con cliente, dirección, ETA y badge de estado. Tocar abre el detalle.
///
/// Los tramos de la línea "hechos" van sólidos; los pendientes, tenues.
class StopTimelineTile extends StatelessWidget {
  const StopTimelineTile({
    super.key,
    required this.stop,
    required this.status,
    required this.isFirst,
    required this.isLast,
    required this.topDone,
    required this.bottomDone,
  });

  final DriverRouteStop stop;

  /// Estado efectivo a mostrar (puede diferir del de [stop] si se resolvió
  /// localmente y aún no sincronizó).
  final DriverRouteStopStatus status;

  final bool isFirst;
  final bool isLast;

  /// El tramo de línea que entra por arriba / sale por abajo está "hecho"
  /// (sólido) en vez de pendiente (tenue).
  final bool topDone;
  final bool bottomDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name =
        stop.customerName ?? stop.orderReference ?? 'Parada ${stop.sequence}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(
            status: status,
            sequence: stop.sequence,
            showTop: !isFirst,
            showBottom: !isLast,
            topDone: topDone,
            bottomDone: bottomDone,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              // Espacio entre tarjetas; la línea de la izquierda lo cruza para
              // quedar continua hasta el siguiente nodo.
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
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
                        const SizedBox(height: 12),
                        // Wrap: con letra 1.3x el badge y el ETA bajan de línea
                        // en vez de desbordar.
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DeliveryBadge(status: status),
                            // Parada resuelta con hora confirmada por el backend:
                            // se muestra la HORA DE ENTREGA (o de la fallida). Si
                            // sigue pendiente, la hora estimada (ETA).
                            if (status != DriverRouteStopStatus.pending &&
                                stop.settledAt != null)
                              _TimeChip(
                                label: status == DriverRouteStopStatus.completed
                                    ? 'Entregada'
                                    : 'Fallida',
                                at: stop.settledAt!,
                                color: stopColor(status),
                                icon: status == DriverRouteStopStatus.completed
                                    ? AppIcon.success
                                    : AppIcon.error,
                              )
                            else if (status == DriverRouteStopStatus.pending &&
                                stop.etaAt != null)
                              _EtaChip(at: stop.etaAt!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de ETA: reloj animado + hora.
class _EtaChip extends StatelessWidget {
  const _EtaChip({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedAppIcon(
          AppIcon.pending,
          size: 18,
          color: color,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 6),
        Text(
          'ETA ${formatTime(at)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Fila de hora real de la parada (entregada/fallida): ícono del estado + "HH:mm"
/// en el color del estado. Deja claro A QUÉ HORA se entregó (o falló) la parada.
class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.at,
    required this.color,
    required this.icon,
  });

  final String label;
  final DateTime at;
  final Color color;
  final AppIcon icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedAppIcon(
          icon,
          size: 18,
          color: color,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 6),
        Text(
          '$label ${formatTime(at)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Carril del timeline: línea superior, nodo y línea inferior. El nodo se
/// alinea cerca del título de la tarjeta.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.status,
    required this.sequence,
    required this.showTop,
    required this.showBottom,
    required this.topDone,
    required this.bottomDone,
  });

  final DriverRouteStopStatus status;
  final int sequence;
  final bool showTop;
  final bool showBottom;
  final bool topDone;
  final bool bottomDone;

  /// Alto del tramo superior: deja al nodo a la altura del título.
  static const double _topGap = 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          SizedBox(
            height: _topGap,
            child: _Segment(visible: showTop, done: topDone),
          ),
          _Node(status: status, sequence: sequence),
          Expanded(
            child: _Segment(visible: showBottom, done: bottomDone),
          ),
        ],
      ),
    );
  }
}

/// Tramo vertical de la línea del timeline (sólido si está "hecho", tenue si no).
class _Segment extends StatelessWidget {
  const _Segment({required this.visible, required this.done});

  final bool visible;
  final bool done;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final color = done
        ? AppColors.success
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15);
    return Center(
      child: Container(
        width: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Marcador del nodo: círculo con el número de secuencia (pendiente) o el ícono
/// animado del estado (entregada/fallida), en el color del estado.
class _Node extends StatelessWidget {
  const _Node({required this.status, required this.sequence});

  final DriverRouteStopStatus status;
  final int sequence;

  @override
  Widget build(BuildContext context) {
    final color = stopColor(status);
    final resolved = status != DriverRouteStopStatus.pending;
    return Container(
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
        child: resolved
            ? AnimatedAppIcon(
                stopAppIcon(status),
                state: status == DriverRouteStopStatus.completed
                    ? AppIconState.success
                    : AppIconState.error,
                size: 22,
                color: Colors.white,
                excludeFromSemantics: true,
              )
            : Text(
                '$sequence',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
