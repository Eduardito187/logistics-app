import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/api/export.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/map/dark_map_canvas.dart';
import '../../../../core/theme/app_colors.dart';
import 'stop_pin.dart';

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
          const DarkMapTiles(),
          const DarkMapScrim(),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 52,
                height: TeardropPin.heightFor(52),
                // La punta del pin apunta a la coordenada.
                alignment: Alignment.topCenter,
                child: const TeardropPin(
                  color: AppColors.brand,
                  size: 52,
                  glow: true,
                  child: AnimatedAppIcon(
                    AppIcon.place,
                    color: Colors.white,
                    size: 30,
                    semanticLabel: 'Destino',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
