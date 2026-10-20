import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/export.dart';
import '../../../../core/map/osm_tile_layer.dart';

/// Mapa a pantalla completa centrado en la parada (navegación de campo sin
/// depender de una app externa).
class StopMapScreen extends StatelessWidget {
  const StopMapScreen({super.key, required this.stop});

  final DriverRouteStop stop;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(stop.lat!, stop.lng!);
    return Scaffold(
      appBar: AppBar(
        title: Text(stop.customerName ?? 'Parada ${stop.sequence}'),
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: point, initialZoom: 15),
        children: [
          const OsmTileLayer(),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 48,
                height: 48,
                child: const Icon(Icons.place, color: Colors.red, size: 48),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
