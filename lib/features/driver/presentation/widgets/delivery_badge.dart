import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/icons/icons.dart';
import '../driver_route_status.dart';

/// Badge de estado de una parada: ícono animado DisTrack + etiqueta, teñido con
/// el color del estado ([stopColor]). El ícono se dibuja/anima al aparecer
/// (tilde en "Entregada", sacudida en "Fallida"), así el resultado se nota de
/// un vistazo bajo el sol. Para la tarjeta del timeline y la de tablet.
class DeliveryBadge extends StatelessWidget {
  const DeliveryBadge({super.key, required this.status});

  final DriverRouteStopStatus status;

  @override
  Widget build(BuildContext context) {
    final color = stopColor(status);
    final label = stopStatusLabel(status);
    // El estado del ícono marca su animación de entrada: éxito dibuja el tilde,
    // error lo sacude; pendiente queda quieto.
    final iconState = switch (status) {
      DriverRouteStopStatus.completed => AppIconState.success,
      DriverRouteStopStatus.failed => AppIconState.error,
      _ => AppIconState.idle,
    };
    return Semantics(
      container: true,
      label: 'Estado: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedAppIcon(
                stopAppIcon(status),
                state: iconState,
                size: 18,
                color: color,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 7),
              // Flexible: en una tarjeta angosta (teléfono chico + letra 1.3x)
              // la etiqueta se recorta con "…" en vez de desbordar el badge.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
