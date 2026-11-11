import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/layout/adaptive_card_rows.dart';
import '../../../../core/layout/breakpoints.dart';
import '../controllers/locally_settled_stops.dart';
import 'route_points.dart';
import 'stop_card.dart';
import 'stop_timeline_tile.dart';

/// Lista de paradas de la ruta, ordenadas por secuencia. En teléfono es un
/// **timeline vertical** tipo tracking (se lee mejor de una columna); en tablet
/// ancha son tarjetas repartidas en 2 columnas. Las paradas resueltas en este
/// teléfono (aún en la cola offline) se muestran ya con su estado final.
class RouteList extends ConsumerWidget {
  const RouteList({super.key, required this.route});

  final DriverRoute route;

  /// Un tramo de la línea está "hecho" (sólido) cuando la parada ya se atendió
  /// (entregada o fallida), no cuando sigue pendiente.
  static bool _done(DriverRouteStopStatus status) =>
      status != DriverRouteStopStatus.pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memoizado por ruta: alternar mapa/lista no reordena de nuevo.
    final stops = sortedStops(route);
    final settled = ref.watch(locallySettledStopsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Teléfono (compact): timeline de una columna.
        if (AppBreakpoints.sizeFor(constraints.maxWidth) ==
            WindowSize.compact) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: stops.length,
            itemBuilder: (context, i) {
              final status = effectiveStopStatus(stops[i], settled);
              final prevStatus = i > 0
                  ? effectiveStopStatus(stops[i - 1], settled)
                  : null;
              return StopEntrance(
                index: i,
                child: StopTimelineTile(
                  stop: stops[i],
                  status: status,
                  isFirst: i == 0,
                  isLast: i == stops.length - 1,
                  topDone: prevStatus != null && _done(prevStatus),
                  bottomDone: _done(status),
                ),
              );
            },
          );
        }

        // Tablet ancha: tarjetas en 2 columnas (sin la línea del timeline).
        return AdaptiveCardRows(
          maxColumns: 2,
          itemCount: stops.length,
          itemBuilder: (context, i) => StopEntrance(
            index: i,
            child: StopCard(
              stop: stops[i],
              status: effectiveStopStatus(stops[i], settled),
            ),
          ),
        );
      },
    );
  }
}
