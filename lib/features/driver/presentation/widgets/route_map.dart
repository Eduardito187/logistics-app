import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/export.dart';
import '../../../../core/map/osm_tile_layer.dart';
import '../../../../core/widgets/empty_state.dart';
import '../driver_route_status.dart';
import 'stop_pin.dart';

/// Mapa OSM con las paradas de la ruta como marcadores tocables.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.route});

  final DriverRoute route;

  @override
  Widget build(BuildContext context) {
    final located = route.stops
        .where((s) => s.lat != null && s.lng != null)
        .toList(growable: false);
    if (located.isEmpty) {
      return const EmptyState(
        icon: Icons.location_off,
        title: 'Sin ubicaciones',
        message: 'Las paradas no tienen coordenadas. Usa la lista.',
      );
    }

    final center = LatLng(located.first.lat!, located.first.lng!);
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        const OsmTileLayer(),
        MarkerLayer(
          markers: [
            for (final stop in located)
              Marker(
                point: LatLng(stop.lat!, stop.lng!),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => openStopDetail(context, stop),
                  child: StopPin(stop: stop),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
