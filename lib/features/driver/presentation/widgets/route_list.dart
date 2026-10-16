import 'package:flutter/material.dart';

import '../../../../core/api/export.dart';
import 'stop_card.dart';

/// Lista de paradas de la ruta, ordenadas por secuencia.
class RouteList extends StatelessWidget {
  const RouteList({super.key, required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context) {
    final stops = [...route.stops]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stops.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final stop = stops[i];
        return StopCard(stop: stop);
      },
    );
  }
}
