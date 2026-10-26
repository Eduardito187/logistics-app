import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/layout/adaptive_card_rows.dart';
import '../controllers/locally_settled_stops.dart';
import 'route_points.dart';
import 'stop_card.dart';

/// Lista de paradas de la ruta, ordenadas por secuencia. En tablets las
/// tarjetas se reparten en 2–3 columnas. Las paradas resueltas en este
/// teléfono (aún en la cola offline) se muestran ya con su estado final.
class RouteList extends ConsumerWidget {
  const RouteList({super.key, required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memoizado por ruta: alternar mapa/lista no reordena de nuevo.
    final stops = sortedStops(route);
    final settled = ref.watch(locallySettledStopsProvider);
    return AdaptiveCardRows(
      itemCount: stops.length,
      itemBuilder: (context, i) => StopCard(
        stop: stops[i],
        status: effectiveStopStatus(stops[i], settled),
      ),
    );
  }
}
