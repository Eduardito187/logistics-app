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
///
/// Pensado para teléfonos de 1 GB:
/// - las opciones del mapa y la capa de tiles se crean una sola vez (al
///   refrescar la flota no se recrea el cliente HTTP de tiles ni se reinicia la
///   cámara);
/// - los marcadores se recalculan solo si cambió alguna posición: el clustering
///   compara la lista por identidad y, con una lista nueva en cada build,
///   reagrupaba todos los camiones en cada reconstrucción;
/// - animaciones del clustering más cortas (menos frames por gesto).
class FleetMap extends StatefulWidget {
  const FleetMap({super.key, required this.vehicles});

  final List<VehicleLive> vehicles;

  @override
  State<FleetMap> createState() => _FleetMapState();
}

class _FleetMapState extends State<FleetMap> {
  late final MapOptions _options = MapOptions(
    initialCenter: LatLng(widget.vehicles.first.lat, widget.vehicles.first.lng),
    initialZoom: 12,
  );

  late List<Marker> _markers = _buildMarkers(widget.vehicles);

  @override
  void didUpdateWidget(FleetMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!sameFleetPositions(oldWidget.vehicles, widget.vehicles)) {
      _markers = _buildMarkers(widget.vehicles);
    }
  }

  List<Marker> _buildMarkers(List<VehicleLive> vehicles) {
    return List<Marker>.unmodifiable([
      for (final vehicle in vehicles)
        Marker(
          key: ValueKey(vehicle.vehicleId),
          point: LatLng(vehicle.lat, vehicle.lng),
          width: 48,
          height: 48,
          child: TruckMarker(
            vehicle: vehicle,
            onTap: () => VehicleSheet.show(context, vehicle),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: _options,
      children: [
        const OsmTileLayer(),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 48,
            size: const Size(44, 44),
            padding: const EdgeInsets.all(48),
            markers: _markers,
            animationsOptions: _clusterAnimations,
            builder: (context, clusterMarkers) =>
                _ClusterBadge(count: clusterMarkers.length),
          ),
        ),
      ],
    );
  }
}

/// Animaciones del clustering acortadas (default 500 ms): menos frames por
/// zoom/despliegue en GPUs de gama baja, sin perder la transición.
const AnimationsOptions _clusterAnimations = AnimationsOptions(
  zoom: Duration(milliseconds: 250),
  fitBound: Duration(milliseconds: 250),
  centerMarker: Duration(milliseconds: 250),
  spiderfy: Duration(milliseconds: 250),
);

/// `true` si ambas listas tienen los mismos camiones en las mismas posiciones y
/// estado (lo único que dibuja el marcador). Evita reagrupar el mapa cuando un
/// refresco devuelve exactamente lo mismo.
@visibleForTesting
bool sameFleetPositions(List<VehicleLive> a, List<VehicleLive> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i];
    final y = b[i];
    if (x.vehicleId != y.vehicleId ||
        x.lat != y.lat ||
        x.lng != y.lng ||
        x.moving != y.moving ||
        x.speedKph != y.speedKph ||
        x.recordedAt != y.recordedAt) {
      return false;
    }
  }
  return true;
}

/// Burbuja de un grupo de camiones con su cantidad.
class _ClusterBadge extends StatelessWidget {
  const _ClusterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.info,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          '$count',
          // Sin escalar: la burbuja es de tamaño fijo (44 dp) y con letra
          // grande el número se saldría del círculo.
          textScaler: TextScaler.noScaling,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
