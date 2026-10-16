import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../config/app_config.dart';
import 'tile_cache.dart';

export 'tile_cache.dart' show kMapUserAgent, kMapUserAgentPackageName;

/// Zoom máximo que pide tiles al servidor. Más allá se escala el tile de este
/// nivel (no se baja un nivel nuevo): z19 cuadruplica los tiles de z18 sin
/// aportar nada útil para ubicar una parada.
const int kMapMaxNativeZoom = 18;

/// Zoom máximo permitido (con sobre-escalado desde [kMapMaxNativeZoom]).
const double kMapMaxZoom = 19;

/// Anillos de tiles fuera de pantalla que se conservan al mover el mapa.
///
/// El default de flutter_map es 2 (+1 de precarga): en un teléfono de 1 GB
/// eso son decenas de tiles decodificados (256 KB c/u) compitiendo con la
/// cámara. 1 alcanza para que el paneo no muestre huecos.
const int kMapKeepBuffer = 1;

/// Anillos de tiles que se precargan fuera de la pantalla (0 = solo lo visible).
const int kMapPanBuffer = 0;

/// Capa de tiles central y reutilizable para todos los mapas de la app.
///
/// La URL sale de [AppConfig.mapTilesUrl]: por defecto el tile público de OSM
/// en desarrollo y el servidor self-host (`MAP_TILES_URL`) en producción
/// (ADR 013/I-10). Nunca se usa Google.
///
/// Afinada para teléfonos de gama baja:
/// - sin retina (no pide tiles @2x ni simula retina: 4x menos memoria),
/// - buffers de tiles bajos ([kMapKeepBuffer]/[kMapPanBuffer]),
/// - `maxNativeZoom` acotado ([kMapMaxNativeZoom]),
/// - tiles sin fundido (el fade-in repinta cada tile varias veces),
/// - los tiles con error se descartan al salir de pantalla.
///
/// Los tiles decodificados viven en la `ImageCache` global, que `main.dart`
/// limita a 40 MB / 80 imágenes.
///
/// Los tiles bajados se guardan en disco ([MapTileCache], zonas sin señal):
/// si el tile ya está en el teléfono se muestra sin red. Todos los mapas
/// comparten un único cliente HTTP; sin carpeta de la app (tests) se piden a
/// la red sin caché.
///
/// Igual conviene [OsmTileLayer] en widgets que se reconstruyen seguido: así
/// la `TileLayer` no se recrea en cada `build`.
TileLayer buildOsmTileLayer({int? maxNativeZoom, double? maxZoom}) {
  return TileLayer(
    urlTemplate: AppConfig.mapTilesUrl,
    tileProvider: CachedOsmTileProvider(),
    userAgentPackageName: kMapUserAgentPackageName,
    retinaMode: false,
    maxNativeZoom: maxNativeZoom ?? kMapMaxNativeZoom,
    maxZoom: maxZoom ?? kMapMaxZoom,
    keepBuffer: kMapKeepBuffer,
    panBuffer: kMapPanBuffer,
    tileDisplay: const TileDisplay.instantaneous(),
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
  );
}

/// Capa de tiles OSM que se construye una sola vez por mapa.
///
/// Equivale a [buildOsmTileLayer] pero conserva la misma `TileLayer` aunque
/// el padre se reconstruya, p. ej. al llegar posiciones
/// nuevas de la flota. Uso: `children: [const OsmTileLayer(), MarkerLayer(...)]`.
class OsmTileLayer extends StatefulWidget {
  const OsmTileLayer({super.key});

  @override
  State<OsmTileLayer> createState() => _OsmTileLayerState();
}

class _OsmTileLayerState extends State<OsmTileLayer> {
  late final TileLayer _layer = buildOsmTileLayer();

  @override
  Widget build(BuildContext context) => _layer;
}
