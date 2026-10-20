import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/layout/adaptive_card_rows.dart';
import 'stop_card.dart';

/// Lista de paradas de la ruta, ordenadas por secuencia. En tablets las
/// tarjetas se reparten en 2–3 columnas.
class RouteList extends StatelessWidget {
  const RouteList({super.key, required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context) {
    final stops = [...route.stops]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return AdaptiveCardRows(
      itemCount: stops.length,
      itemBuilder: (context, i) => StopCard(stop: stops[i]),
    );
  }
}
