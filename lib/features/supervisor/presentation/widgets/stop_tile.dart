import 'package:flutter/material.dart';

import '../../../../core/api/models/planned_stop.dart';
import '../supervisor_labels.dart';

/// Una parada del plan dentro de la LÍNEA DE TIEMPO del viaje: a la izquierda
/// el número unido por una línea a la parada anterior y a la siguiente; a la
/// derecha una tarjeta con todo lo de la parada, sin recortar nada (pedido,
/// cliente, dirección completa, la hora que pidió el cliente y la hora
/// estimada de llegada).
///
/// [footer] son las acciones de quien planifica (subir, bajar, quitar).
class StopTile extends StatelessWidget {
  const StopTile({
    super.key,
    required this.position,
    required this.stop,
    this.eta,
    this.isFirst = false,
    this.isLast = false,
    this.footer,
  });

  final int position;
  final PlannedStop stop;

  /// Hora estimada de llegada (`null` = todavía no calculada).
  final DateTime? eta;

  /// Primera / última parada: la línea no sigue hacia arriba / abajo.
  final bool isFirst;
  final bool isLast;

  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final window = stop.timeWindow;
    final address = stop.shortAddress ?? stop.address;
    final meta = <String>[
      'Carga #${stop.loadOrder}',
      if (stop.lane != null) 'Carril ${stop.lane}',
      if (stop.etaMinutes != null) '${stop.etaMinutes} min',
    ];
    final line = scheme.primary.withValues(alpha: 0.35);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Riel de la línea de tiempo.
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 14,
                  color: isFirst ? Colors.transparent : line,
                ),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 1.5),
                  ),
                  child: Text(
                    '$position',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            stopTitle(stop.orderReference, position),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (eta != null) ...[
                          const SizedBox(width: 8),
                          _EtaBadge(eta: eta!),
                        ],
                      ],
                    ),
                    if (stop.customerName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        stop.customerName!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (window != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        timeWindowText(window.from, window.to),
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      meta.join(' · '),
                      style: TextStyle(color: scheme.outline),
                    ),
                    if (footer != null) ...[const Divider(height: 16), footer!],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hora estimada de llegada, destacada en la esquina de la tarjeta.
class _EtaBadge extends StatelessWidget {
  const _EtaBadge({required this.eta});

  final DateTime eta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Llega ${formatHour(eta)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Llega',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          Text(
            formatHour(eta),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
