import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/map/osm_tile_layer.dart';
import '../../../../core/theme/app_colors.dart';
import 'truck_marker.dart';
import 'vehicle_sheet.dart';

/// Mapa OSM de la flota: un marcador por camión, con clustering al alejar el
/// zoom para escalar con flotas grandes.
class FleetMap extends StatelessWidget {
  const FleetMap({super.key, required this.vehicles});

  final List<VehicleLive> vehicles;

  @override
  Widget build(BuildContext context) {
    final first = vehicles.first;
    final center = LatLng(first.lat, first.lng);

    // Un marcador por camión; el clustering los agrupa al alejar el zoom para
    // que el mapa escale con flotas grandes.
    final List<Marker> markers = [
      for (final vehicle in vehicles)
        Marker(
          point: LatLng(vehicle.lat, vehicle.lng),
          width: 48,
          height: 48,
          child: TruckMarker(
            vehicle: vehicle,
            onTap: () => VehicleSheet.show(context, vehicle),
          ),
        ),
    ];

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        buildOsmTileLayer(),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 48,
            size: const Size(44, 44),
            padding: const EdgeInsets.all(48),
            markers: markers,
            builder: (context, clusterMarkers) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${clusterMarkers.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
