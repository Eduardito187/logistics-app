import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import 'osm_tile_layer.dart';

/// Tematizado OSCURO reutilizable de los tiles del mapa, al estilo de las apps
/// de parking: tiles desaturados y oscurecidos con un glow radial tenue a
/// color de marca sobre el centro. Se ve oscuro SIEMPRE (en tema claro y
/// oscuro de la app) porque el filtro vive encima de los tiles, no depende del
/// `ThemeData`.
///
/// Importante: NO cambia el servidor de tiles ni la caché offline. Es solo un
/// filtro visual encima de [OsmTileLayer]: un único `ColorFiltered` (barato,
/// una sola capa) para que no sume costo por tile.
///
/// Uso en los `children` de un `FlutterMap` (reemplaza a `const OsmTileLayer()`
/// y agrega el scrim justo encima de los tiles, debajo del trazo y las
/// paradas):
/// ```dart
/// children: [
///   const DarkMapTiles(),
///   const DarkMapScrim(),
///   ...resto de capas...
/// ],
/// ```

/// Matriz de color que desatura (deja ~25% de saturación) y oscurece (≈0,45)
/// los tiles claros de OSM. El offset −10 por canal hunde un poco las sombras
/// para que el asfalto quede gris pizarra y no gris medio.
///
/// Orden de `ColorFilter.matrix`: 5 valores por fila (R, G, B, A y offset),
/// 4 filas (R', G', B', A').
const List<double> kDarkTileMatrix = <double>[
  0.1843, 0.2414, 0.0244, 0, -10, // R'
  0.0718, 0.3539, 0.0244, 0, -10, // G'
  0.0718, 0.2414, 0.1369, 0, -10, // B'
  0, 0, 0, 1, 0, // A'
];

/// Capa de tiles OSM tematizada en oscuro. Envuelve [OsmTileLayer] (que se
/// construye una sola vez) en un único `ColorFiltered`, así no se recrea ni la
/// capa de tiles ni el filtro en cada `build` del mapa.
class DarkMapTiles extends StatelessWidget {
  const DarkMapTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColorFiltered(
      colorFilter: ColorFilter.matrix(kDarkTileMatrix),
      child: OsmTileLayer(),
    );
  }
}

/// Scrim encima de los tiles: glow radial de marca muy sutil sobre el centro
/// (como el glow del parking, en rojo DisTrack) más un viñeteado oscuro en los
/// bordes para dar profundidad. No intercepta toques (`IgnorePointer`).
///
/// Se coloca como un hijo más del `FlutterMap`, justo después de [DarkMapTiles]
/// y antes del trazo y las paradas, para que los marcadores queden nítidos
/// encima. Usa `Positioned.fill` porque los hijos de `FlutterMap` viven en un
/// `Stack` suelto: sin esto el `Container` mediría cero.
class DarkMapScrim extends StatelessWidget {
  const DarkMapScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Color(0x1FE30613), // brand ~12% en el centro (glow)
                Color(0x00141414), // transparente en el medio
                Color(0x59141414), // viñeteado Noche ~35% en los bordes
              ],
              stops: [0.0, 0.42, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// Color sugerido para trazos/estados sobre el canvas oscuro cuando se quiere
/// el ámbar de acento (reservado por marca a alertas; aquí solo como ayuda de
/// legibilidad si algún mapa lo necesita). No se usa por defecto.
const Color kDarkMapAccent = AppColors.accent;
