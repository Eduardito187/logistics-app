import 'package:flutter/material.dart';

import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/theme/app_colors.dart';

/// Marcador de un camión en el mapa de flota; verde si se mueve, ámbar si está
/// detenido.
class TruckMarker extends StatelessWidget {
  const TruckMarker({super.key, required this.vehicle, required this.onTap});

  final VehicleLive vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = vehicle.moving ? AppColors.success : AppColors.warning;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
      ),
    );
  }
}
