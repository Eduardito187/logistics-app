import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../driver_route_status.dart';

/// Marcador numerado de una parada en el mapa, coloreado según su estado.
class StopPin extends StatelessWidget {
  const StopPin({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context) {
    final color = stopColor(stop.status);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '${stop.sequence}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
