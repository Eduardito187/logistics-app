import 'package:flutter/material.dart';

import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../driver/presentation/widgets/active_delivery/truck_marker.dart'
    as driver_map;

/// Marcador de un camión en el mapa de flota: el MISMO camión visto desde
/// arriba que ve el chofer en su mapa, apuntando hacia donde avanza (rumbo de
/// la telemetría). Un punto en la esquina dice si se mueve (verde) o está
/// detenido (ámbar).
class TruckMarker extends StatelessWidget {
  const TruckMarker({super.key, required this.vehicle, required this.onTap});

  final VehicleLive vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = vehicle.moving ? AppColors.success : AppColors.warning;
    final plate = vehicle.plate;
    return Semantics(
      button: true,
      label:
          '${plate == null ? 'Camión' : 'Camión $plate'}, '
          '${vehicle.moving ? 'en movimiento' : 'detenido'}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: driver_map.TruckMarker(
                headingDegrees: vehicle.heading?.toDouble(),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
