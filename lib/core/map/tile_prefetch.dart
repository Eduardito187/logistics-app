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

/// Tope de tiles de UN zoom dentro de la precarga. Sin esto, en una ruta
/// corta el zoom más alto (el que más tiles tiene) se comería todo el tope
/// total; así cada zoom deja lugar a los demás y la precarga queda repartida.
const int kPrefetchMaxTilesPerZoom = 300;

/// Descargas simultáneas de la precarga: UNA. Comparte el pool de conexiones
/// con los tiles visibles del mapa; con una sola descarga a la vez la precarga
/// no le quita lugar al mapa que el chofer está mirando (y respeta la tile
/// usage policy de OSM, que pide ≤ 2 conexiones por cliente).
const int kPrefetchConcurrency = 1;

/// Espera antes de arrancar la precarga: deja pasar la transición de la
/// pantalla y el primer pintado del mapa con sus tiles visibles.
const Duration kPrefetchStartDelay = Duration(seconds: 3);

/// Tiles por lote al revisar qué ya está en disco: la clave de caché (UUID v5,
/// SHA-1 en Dart) y el `exists` se hacen de a lotes, intercalados con las
/// descargas, en vez de cientos de golpe en el isolate de UI.
const int kPrefetchExistsBatchSize = 50;

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
///
/// Ningún zoom aporta más de [maxTilesPerZoom] tiles.
List<TileCoordinates> computeRouteTiles(
  List<LatLng> points, {
  int minZoom = 13,
  int maxZoom = 16,
  int maxTiles = kPrefetchMaxTiles,
  int maxTilesPerZoom = kPrefetchMaxTilesPerZoom,
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
    final remaining = math.min(maxTiles - result.length, maxTilesPerZoom);
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
  _PrefetchJob(this.key, this.cache);

  /// Clave de la ruta (ver [routePrefetchKey]) y caché destino.
  final String key;
  final MapTileCache cache;

  final CancelToken token = CancelToken();
  final Completer<void> _stoppedSignal = Completer<void>();
  bool _stopped = false;

  /// Precarga en curso (la devuelven las llamadas repetidas de la misma ruta).
  late final Future<void> future;

  bool get stopped => _stopped;

  /// Se completa al cancelar: corta la espera inicial sin dejar timers vivos.
  Future<void> get stoppedSignal => _stoppedSignal.future;

  void stop() {
    if (_stopped) {
      return;
    }
    _stopped = true;
    token.cancel('precarga de tiles cancelada');
    _stoppedSignal.complete();
  }
}

_PrefetchJob? _currentJob;

/// Rutas ya precargadas por completo en esta sesión, por caché. Una ruta se
/// precarga UNA vez: volver a abrir "Entrega en curso" no repite cientos de
/// chequeos de disco. Si la precarga se canceló o se abandonó (sin señal), no
/// cuenta como hecha y se reintenta la próxima vez.
final Expando<Set<String>> _completedRoutes = Expando<Set<String>>(
  'prefetchRouteTiles',
);

/// Cancela la precarga en curso (si hay). Lo ya bajado queda en la caché.
void cancelRouteTilePrefetch() {
  _currentJob?.stop();
  _currentJob = null;
}

/// Olvida qué rutas ya se precargaron (tests).
@visibleForTesting
void resetRouteTilePrefetchMemo([MapTileCache? cache]) {
  _completedRoutes[cache ?? MapTileCache.instance] = null;
}

/// Clave de memoización de una precarga: los puntos (redondeados a ~10 m) y
/// los parámetros que cambian el conjunto de tiles.
String routePrefetchKey(
  List<LatLng> points, {
  int minZoom = 13,
  int maxZoom = 16,
  int maxTiles = kPrefetchMaxTiles,
  int maxTilesPerZoom = kPrefetchMaxTilesPerZoom,
}) {
  final buffer = StringBuffer('$minZoom-$maxZoom-$maxTiles-$maxTilesPerZoom');
  for (final p in points) {
    buffer
      ..write('|')
      ..write(p.latitude.toStringAsFixed(4))
      ..write(',')
      ..write(p.longitude.toStringAsFixed(4));
  }
  return buffer.toString();
}

/// Precarga en la caché de disco los tiles de la zona de la ruta del día, para
/// que el mapa se vea aunque después no haya señal.
///
/// Uso típico al abrir "Entrega en curso", sin esperar el resultado:
/// `unawaited(prefetchRouteTiles(stops.map((s) => s.position).toList()))`.
///
/// - No compite con el mapa visible: arranca tras [startDelay]
///   ([kPrefetchStartDelay]) y baja de a [concurrency] ([kPrefetchConcurrency]
///   = 1) en segundo plano.
/// - Una vez por ruta y por sesión: si la misma ruta ([routeKey], o la clave
///   de [routePrefetchKey]) ya se precargó completa, no hace nada; si está en
///   curso, devuelve esa misma precarga.
/// - Calcula los tiles con [computeRouteTiles] (rectángulo de los puntos con
///   margen; tope [maxTiles]). [maxZoom] se acota al zoom nativo del mapa.
/// - Los tiles que ya están en disco no se vuelven a pedir; el chequeo se hace
///   de a lotes de [kPrefetchExistsBatchSize], intercalado con las descargas.
/// - Corre con Wi-Fi o con datos: el tope lo hace barato (≲ 9 MB) y el
///   chofer suele salir del depósito sin Wi-Fi.
/// - Se abandona tras varios errores de red seguidos (sin señal) o ante un
///   429 del servidor.
/// - Una sola precarga a la vez: llamarla con otra ruta cancela la anterior;
///   [cancelRouteTilePrefetch] la corta (también durante la espera inicial).
/// - Nunca lanza: si no hay caché (tests, web) no hace nada.
Future<void> prefetchRouteTiles(
  List<LatLng> points, {
  int minZoom = 13,
  int maxZoom = 16,
  int maxTiles = kPrefetchMaxTiles,
  int maxTilesPerZoom = kPrefetchMaxTilesPerZoom,
  int concurrency = kPrefetchConcurrency,
  Duration startDelay = kPrefetchStartDelay,
  String? routeKey,
  MapTileCache? cache,
}) {
  final tileCache = cache ?? MapTileCache.instance;
  final key =
      routeKey ??
      routePrefetchKey(
        points,
        minZoom: minZoom,
        maxZoom: maxZoom,
        maxTiles: maxTiles,
        maxTilesPerZoom: maxTilesPerZoom,
      );
  if (_completedRoutes[tileCache]?.contains(key) ?? false) {
    return Future<void>.value();
  }
  final running = _currentJob;
  if (running != null &&
      !running.stopped &&
      running.key == key &&
      identical(running.cache, tileCache)) {
    return running.future;
  }
  cancelRouteTilePrefetch();
  final job = _PrefetchJob(key, tileCache);
  _currentJob = job;
  job.future = _runPrefetch(
    job,
    points,
    minZoom: minZoom,
    maxZoom: maxZoom,
    maxTiles: maxTiles,
    maxTilesPerZoom: maxTilesPerZoom,
    concurrency: concurrency,
    startDelay: startDelay,
  );
  return job.future;
}

Future<void> _runPrefetch(
  _PrefetchJob job,
  List<LatLng> points, {
  required int minZoom,
  required int maxZoom,
  required int maxTiles,
  required int maxTilesPerZoom,
  required int concurrency,
  required Duration startDelay,
}) async {
  final tileCache = job.cache;
  TileProvider? provider;
  try {
    if (startDelay > Duration.zero) {
      final delay = Completer<void>();
      final timer = Timer(startDelay, delay.complete);
      await Future.any([delay.future, job.stoppedSignal]);
      timer.cancel();
    }
    if (job.stopped) {
      return;
    }
    final store = await tileCache.store;
    if (store == null || job.stopped) {
      return;
    }
    final tiles = computeRouteTiles(
      points,
      minZoom: minZoom,
      maxZoom: math.min(maxZoom, kMapMaxNativeZoom),
      maxTiles: maxTiles,
      maxTilesPerZoom: maxTilesPerZoom,
    );
    if (tiles.isEmpty) {
      _markCompleted(job);
      return;
    }
    // Misma URL que pide el mapa (misma clave en la caché).
    final layer = buildOsmTileLayer();
    final tileProvider = provider = layer.tileProvider;
    var consecutiveFailures = 0;
    var downloaded = 0;

    for (
      var start = 0;
      start < tiles.length && !job.stopped;
      start += kPrefetchExistsBatchSize
    ) {
      final end = math.min(start + kPrefetchExistsBatchSize, tiles.length);
      final urls = [
        for (var i = start; i < end; i++)
          tileProvider.getTileUrl(tiles[i], layer),
      ];
      // Lote de chequeos de disco en paralelo (E/S asíncrona).
      final present = await Future.wait([
        for (final url in urls) store.exists(MapTileCache.cacheKeyFor(url)),
      ]);
      final missing = [
        for (var i = 0; i < urls.length; i++)
          if (!present[i]) urls[i],
      ];
      var next = 0;

      Future<void> worker() async {
        while (!job.stopped && next < missing.length) {
          final url = missing[next++];
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
    }
    if (!job.stopped) {
      _markCompleted(job);
    }
    if (downloaded > 0) {
      unawaited(tileCache.trim());
    }
  } catch (error) {
    debugPrint('Precarga de tiles interrumpida: $error');
  } finally {
    provider?.dispose();
    if (identical(_currentJob, job)) {
      _currentJob = null;
    }
  }
}

void _markCompleted(_PrefetchJob job) {
  (_completedRoutes[job.cache] ??= <String>{}).add(job.key);
}
