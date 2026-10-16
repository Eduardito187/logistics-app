import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import '../../../../core/widgets/status_pill.dart';
import '../driver_route_status.dart';

/// Resumen de avance de la ruta: entregadas/total y el estado general.
class RouteSummary extends StatelessWidget {
  const RouteSummary({super.key, required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${route.completedStops}/${route.totalStops} entregadas · '
              '${route.stopsRemaining} por hacer',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          StatusPill(
            routeStatusLabel(route.status),
            tone: route.status == DriverRouteStatus.completed
                ? PillTone.success
                : PillTone.info,
          ),
        ],
      ),
    );
  }
}
