import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'osm_tile_layer.dart';
import 'tile_cache.dart';

/// Tope de tiles por precarga. ~600 tiles × ~15 KB ≈ 9 MB en el peor caso:
/// razonable incluso con datos móviles y lejos del tope de disco.
const int kPrefetchMaxTiles = 600;

/// Descargas simultáneas de la precarga. La tile usage policy de OSM pide no
/// más de 2 conexiones por cliente; además así no compite con la API.
const int kPrefetchConcurrency = 2;

/// Errores de red seguidos tras los que se abandona la precarga (sin señal:
/// no tiene sentido seguir intentando tile por tile).
const int _maxConsecutiveFailures = 5;

/// Latitud máxima de la proyección Web Mercator.
const double _maxMercatorLat = 85.05112878;

/// Calcula los tiles a precargar alrededor de [points], de [minZoom] a
/// [maxZoom], sin pasar de [maxTiles].
///
/// Se toma el rectángulo que contiene todos los puntos más un margen
/// ([marginFraction] del lado, mínimo [minMarginDegrees] ≈ 500 m) y se
/// recorren los zooms de menor a mayor: los zooms bajos (vista general, pocos
/// tiles) van completos primero. Si un zoom completo no entra en lo que queda
/// del tope, de ese zoom se toman solo los tiles de cada punto y sus 8
/// vecinos (primero los de los puntos, en el orden de la ruta).
List<TileCoordinates> computeRouteTiles(
  List<LatLng> points, {
  int minZoom = 13,
  int maxZoom = 16,
  int maxTiles = kPrefetchMaxTiles,
  double marginFraction = 0.15,
  double minMarginDegrees = 0.005,
}) {
  if (points.isEmpty || maxTiles <= 0 || maxZoom < minZoom || minZoom < 0) {
    return const [];
  }
  var south = points.first.latitude;
  var north = south;
  var west = points.first.longitude;
  var east = west;
  for (final point in points) {
    south = math.min(south, point.latitude);
    north = math.max(north, point.latitude);
    west = math.min(west, point.longitude);
    east = math.max(east, point.longitude);
  }
  final latMargin = math.max(
    (north - south) * marginFraction,
    minMarginDegrees,
  );
  final lngMargin = math.max((east - west) * marginFraction, minMarginDegrees);
  south -= latMargin;
  north += latMargin;
  west -= lngMargin;
  east += lngMargin;

  final result = <TileCoordinates>[];
  for (var z = minZoom; z <= maxZoom; z++) {
    final remaining = maxTiles - result.length;
    if (remaining <= 0) {
      break;
    }
    final x0 = lngToTileX(west, z);
    final x1 = lngToTileX(east, z);
    final y0 = latToTileY(north, z);
    final y1 = latToTileY(south, z);
    final count = (x1 - x0 + 1) * (y1 - y0 + 1);
    if (count <= remaining) {
      for (var x = x0; x <= x1; x++) {
        for (var y = y0; y <= y1; y++) {
          result.add(TileCoordinates(x, y, z));
        }
      }
      continue;
    }
    // No entra el rectángulo: solo el corredor de las paradas.
    final last = (1 << z) - 1;
    final seen = <TileCoordinates>{};
    final centers = <TileCoordinates>[];
    final neighbours = <TileCoordinates>[];
    for (final point in points) {
      final center = TileCoordinates(
        lngToTileX(point.longitude, z),
        latToTileY(point.latitude, z),
        z,
      );
      if (seen.add(center)) {
        centers.add(center);
      }
    }
    for (final center in centers) {
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          final x = center.x + dx;
          final y = center.y + dy;
          if (x < 0 || y < 0 || x > last || y > last) {
            continue;
          }
          final tile = TileCoordinates(x, y, z);
          if (seen.add(tile)) {
            neighbours.add(tile);
          }
        }
      }
    }
    result.addAll([...centers, ...neighbours].take(remaining));
  }
  return result;
}

/// Columna del tile (esquema XYZ / slippy map) que contiene la longitud [lng].
int lngToTileX(double lng, int zoom) {
  final n = 1 << zoom;
  final clamped = lng.clamp(-180.0, 180.0);
  final x = ((clamped + 180.0) / 360.0 * n).floor();
  return x.clamp(0, n - 1);
}

/// Fila del tile (esquema XYZ / slippy map) que contiene la latitud [lat].
int latToTileY(double lat, int zoom) {
  final n = 1 << zoom;
  final rad = lat.clamp(-_maxMercatorLat, _maxMercatorLat) * math.pi / 180.0;
  final y =
      ((1.0 - math.log(math.tan(rad) + 1.0 / math.cos(rad)) / math.pi) /
              2.0 *
              n)
          .floor();
  return y.clamp(0, n - 1);
}

class _PrefetchJob {
  final CancelToken token = CancelToken();
  bool _stopped = false;

  bool get stopped => _stopped;

  void stop() {
    if (_stopped) {
      return;
    }
    _stopped = true;
    token.cancel('precarga de tiles cancelada');
  }
}

_PrefetchJob? _currentJob;

/// Cancela la precarga en curso (si hay). Lo ya bajado queda en la caché.
void cancelRouteTilePrefetch() {
  _currentJob?.stop();
  _currentJob = null;
}

/// Precarga en la caché de disco los tiles de la zona de la ruta del día, para
/// que el mapa se vea aunque después no haya señal.
///
/// Uso típico al abrir "Entrega en curso", sin esperar el resultado:
/// `unawaited(prefetchRouteTiles(stops.map((s) => s.position).toList()))`.
///
/// - Calcula los tiles con [computeRouteTiles] (rectángulo de los puntos con
///   margen; tope [maxTiles]). [maxZoom] se acota al zoom nativo del mapa.
/// - Los tiles que ya están en disco no se vuelven a pedir.
/// - Baja de a [concurrency] (2 por defecto, como pide OSM) en segundo plano:
///   es todo E/S asíncrona, no bloquea la UI.
/// - Corre con Wi-Fi o con datos: el tope lo hace barato (≲ 9 MB) y el
///   chofer suele salir del depósito sin Wi-Fi.
/// - Se abandona tras varios errores de red seguidos (sin señal) o ante un
///   429 del servidor.
/// - Una sola precarga a la vez: llamarla de nuevo cancela la anterior;
///   [cancelRouteTilePrefetch] la corta.
/// - Nunca lanza: si no hay caché (tests, web) no hace nada.
Future<void> prefetchRouteTiles(
  List<LatLng> points, {
  int minZoom = 13,
  int maxZoom = 16,
  int maxTiles = kPrefetchMaxTiles,
  int concurrency = kPrefetchConcurrency,
  MapTileCache? cache,
}) async {
  cancelRouteTilePrefetch();
  final job = _PrefetchJob();
  _currentJob = job;
  final tileCache = cache ?? MapTileCache.instance;
  try {
    final store = await tileCache.store;
    if (store == null || job.stopped) {
      return;
    }
    final tiles = computeRouteTiles(
      points,
      minZoom: minZoom,
      maxZoom: math.min(maxZoom, kMapMaxNativeZoom),
      maxTiles: maxTiles,
    );
    if (tiles.isEmpty) {
      return;
    }
    // Misma URL que pide el mapa (misma clave en la caché).
    final layer = buildOsmTileLayer();
    final provider = layer.tileProvider;
    var next = 0;
    var consecutiveFailures = 0;
    var downloaded = 0;

    Future<void> worker() async {
      while (!job.stopped && next < tiles.length) {
        final tile = tiles[next++];
        final url = provider.getTileUrl(tile, layer);
        if (await store.exists(MapTileCache.cacheKeyFor(url))) {
          continue;
        }
        if (job.stopped) {
          return;
        }
        try {
          await tileCache.dio.get<List<int>>(
            url,
            cancelToken: job.token,
            options: Options(
              responseType: ResponseType.bytes,
              headers: MapTileCache.headers,
            ),
          );
          consecutiveFailures = 0;
          downloaded++;
        } on DioException catch (error) {
          if (error.type == DioExceptionType.cancel) {
            return;
          }
          if (error.response?.statusCode == 429) {
            job.stop();
            return;
          }
          consecutiveFailures++;
          if (consecutiveFailures >= _maxConsecutiveFailures) {
            job.stop();
            return;
          }
        }
      }
    }

    await Future.wait([
      for (var i = 0; i < math.max(1, concurrency); i++) worker(),
    ]);
    provider.dispose();
    if (downloaded > 0) {
      unawaited(tileCache.trim());
    }
  } catch (error) {
    debugPrint('Precarga de tiles interrumpida: $error');
  } finally {
    if (identical(_currentJob, job)) {
      _currentJob = null;
    }
  }
}
