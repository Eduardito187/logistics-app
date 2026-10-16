import 'package:flutter_map/flutter_map.dart';

import '../config/app_config.dart';

/// Identificador del paquete usado como User-Agent al pedir tiles.
///
/// Los servidores de tiles de OSM exigen un User-Agent propio; se comparte
/// desde acá para que todos los mapas de la app lo usen igual.
const String kMapUserAgentPackageName = 'bo.com.dismac.logistics_app';

/// Capa de tiles central y reutilizable para todos los mapas de la app.
///
/// La URL sale de [AppConfig.mapTilesUrl]: por defecto el tile público de OSM
/// en desarrollo y el servidor self-host (`MAP_TILES_URL`) en producción
/// (ADR 013/I-10). Nunca se usa Google.
TileLayer buildOsmTileLayer() {
  return TileLayer(
    urlTemplate: AppConfig.mapTilesUrl,
    userAgentPackageName: kMapUserAgentPackageName,
  );
}
