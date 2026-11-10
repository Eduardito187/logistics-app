import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/map/osm_tile_layer.dart';
import 'active_delivery/map_round_button.dart';
import 'map_motion.dart';

/// Zoom mínimo de los mapas del chofer: más lejos ya no se distingue la ciudad.
const double kDriverMapMinZoom = 5;

/// Gestos de los mapas del chofer: arrastrar, pellizcar, doble toque y rueda;
/// sin rotar (un mapa girado confunde al manejar).
const InteractionOptions kDriverMapInteraction = InteractionOptions(
  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
);

/// Centro y zoom iniciales que encuadran [points] en un mapa de [size].
///
/// Se calcula ANTES de construir el mapa (en vez de `initialCameraFit`) para
/// que la capa de tiles baje una sola tanda: con `initialCameraFit` primero
/// pide los tiles del centro/zoom inicial, los descarta al reencuadrar y esas
/// descargas quedan perdidas (más datos y errores sueltos sin señal).
({LatLng center, double zoom}) fittedInitialCamera({
  required List<LatLng> points,
  required Size size,
  required EdgeInsets padding,
  required double maxZoom,
}) {
  final base = MapCamera(
    crs: const Epsg3857(),
    center: points.first,
    zoom: 12,
    rotation: 0,
    nonRotatedSize: math.Point(size.width, size.height),
  );
  if (points.length < 2 || size.isEmpty) {
    return (center: points.first, zoom: 15);
  }
  final fitted = CameraFit.coordinates(
    coordinates: points,
    padding: padding,
    maxZoom: maxZoom,
    minZoom: kDriverMapMinZoom,
  ).fit(base);
  return (center: fitted.center, zoom: fitted.zoom);
}

/// Botones grandes de acercar/alejar: con guantes o una mano el pellizco no
/// siempre sale, y en el emulador no hay pellizco.
class MapZoomButtons extends StatefulWidget {
  const MapZoomButtons({super.key, required this.controller});

  final MapController controller;

  @override
  State<MapZoomButtons> createState() => _MapZoomButtonsState();
}

class _MapZoomButtonsState extends State<MapZoomButtons>
    with SingleTickerProviderStateMixin {
  // Se crea en initState (no `late` perezoso): si se dejara perezoso y el
  // widget se desmontara sin tocar el zoom, el acceso desde dispose intentaría
  // crear el AnimationController ya desmontado ("deactivated widget's ancestor").
  late final AnimatedMapMover _mover;

  @override
  void initState() {
    super.initState();
    _mover = AnimatedMapMover(vsync: this, controller: widget.controller);
  }

  @override
  void dispose() {
    _mover.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    // Acumula toques rápidos sobre el zoom pendiente (dos "−" seguidos bajan
    // dos niveles) y recorta al rango permitido del mapa del chofer.
    _mover.zoomBy(
      delta,
      min: kDriverMapMinZoom,
      max: kMapMaxZoom,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapRoundButton(
          tooltip: 'Acercar',
          icon: AppIcon.add,
          onPressed: () => _zoomBy(1),
        ),
        const SizedBox(height: 10),
        MapRoundButton(
          tooltip: 'Alejar',
          icon: AppIcon.remove,
          onPressed: () => _zoomBy(-1),
        ),
      ],
    );
  }
}
