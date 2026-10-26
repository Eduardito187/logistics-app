import 'dart:async';
import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:logistics_app/core/map/tile_cache.dart';
import 'package:logistics_app/core/map/tile_prefetch.dart';

import 'support/fake_tile_adapter.dart';

/// Borra la carpeta temporal del test. En Windows un archivo de tile recién
/// escrito (o la limpieza en segundo plano tras cancelar) puede retener el
/// handle un instante: se reintenta y, si sigue ocupado, se deja (es temp).
Future<void> _deleteQuietly(Directory dir) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
      return;
    } on FileSystemException {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

// Precarga de los tiles de la ruta del día: cálculo de tiles por rectángulo y
// zoom, tope de cantidad, concurrencia, cancelación, memoización por ruta,
// arranque diferido y comportamiento sin caché.
void main() {
  const laPaz = LatLng(-16.5, -68.15);
  const santaCruz = LatLng(-17.7833, -63.1821);

  group('conversión lat/lng → tile (slippy map)', () {
    test('valores conocidos', () {
      expect(lngToTileX(-68.15, 13), 2545);
      expect(latToTileY(-16.5, 13), 4476);
      expect(lngToTileX(-63.1821, 16), 21266);
      expect(latToTileY(-17.7833, 16), 36058);
      expect(lngToTileX(0, 1), 1);
      expect(latToTileY(0, 1), 1);
    });

    test('bordes del mundo quedan dentro del rango', () {
      expect(lngToTileX(180, 3), 7);
      expect(lngToTileX(-180, 3), 0);
      expect(latToTileY(89.9, 3), 0);
      expect(latToTileY(-89.9, 3), 7);
    });
  });

  group('computeRouteTiles', () {
    test('sin puntos o zooms invertidos: vacío', () {
      expect(computeRouteTiles(const []), isEmpty);
      expect(computeRouteTiles([laPaz], minZoom: 16, maxZoom: 13), isEmpty);
      expect(computeRouteTiles([laPaz], maxTiles: 0), isEmpty);
    });

    test('un punto: rectángulo chico con margen, en cada zoom', () {
      final tiles = computeRouteTiles([laPaz]);
      for (var z = 13; z <= 16; z++) {
        final atZoom = tiles.where((t) => t.z == z).toList();
        expect(atZoom, isNotEmpty, reason: 'zoom $z');
        expect(
          atZoom,
          contains(
            TileCoordinates(
              lngToTileX(laPaz.longitude, z),
              latToTileY(laPaz.latitude, z),
              z,
            ),
          ),
        );
      }
      // ±0.005° de margen: a z16 son unos pocos tiles por lado.
      expect(tiles.length, lessThan(100));
    });

    test('ordenados de zoom bajo a alto y sin repetidos', () {
      final tiles = computeRouteTiles([
        laPaz,
        const LatLng(-16.52, -68.12),
        const LatLng(-16.48, -68.09),
      ]);
      expect(tiles.toSet(), hasLength(tiles.length));
      for (var i = 1; i < tiles.length; i++) {
        expect(tiles[i].z, greaterThanOrEqualTo(tiles[i - 1].z));
      }
    });

    test('rectángulo completo cuando entra en el tope', () {
      final points = [laPaz, const LatLng(-16.53, -68.1)];
      final tiles = computeRouteTiles(points, minZoom: 13, maxZoom: 13);
      // Rectángulo con margen, calculado a mano.
      const lat0 = -16.53 - 0.0045;
      const lat1 = -16.5 + 0.0045;
      const lng0 = -68.15 - 0.0075;
      const lng1 = -68.1 + 0.0075;
      final expected =
          (lngToTileX(lng1, 13) - lngToTileX(lng0, 13) + 1) *
          (latToTileY(lat0, 13) - latToTileY(lat1, 13) + 1);
      expect(tiles, hasLength(expected));
    });

    test('ruta larga: respeta el tope y completa primero los zooms bajos', () {
      final tiles = computeRouteTiles([laPaz, santaCruz]);
      expect(tiles.length, lessThanOrEqualTo(kPrefetchMaxTiles));
      expect(tiles.toSet(), hasLength(tiles.length));
      // z13 sobre ~600 km ya no entra entero: va el corredor de las paradas.
      for (final p in [laPaz, santaCruz]) {
        expect(
          tiles,
          contains(
            TileCoordinates(
              lngToTileX(p.longitude, 13),
              latToTileY(p.latitude, 13),
              13,
            ),
          ),
        );
      }
    });

    test('tope bajo: primero los tiles de las paradas', () {
      final tiles = computeRouteTiles(
        [laPaz, santaCruz],
        minZoom: 16,
        maxZoom: 16,
        maxTiles: 2,
      );
      expect(tiles, [
        TileCoordinates(lngToTileX(-68.15, 16), latToTileY(-16.5, 16), 16),
        TileCoordinates(lngToTileX(-63.1821, 16), latToTileY(-17.7833, 16), 16),
      ]);
    });

    test('tope por defecto razonable', () {
      expect(kPrefetchMaxTiles, inInclusiveRange(100, 1000));
      // Una sola descarga a la vez: no compite con los tiles visibles.
      expect(kPrefetchConcurrency, 1);
      expect(
        kPrefetchStartDelay,
        greaterThanOrEqualTo(const Duration(seconds: 2)),
      );
    });
  });

  group('prefetchRouteTiles', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('map_prefetch_test');
    });

    tearDown(() async {
      cancelRouteTilePrefetch();
      await _deleteQuietly(tmp);
    });

    MapTileCache cacheWith(FakeTileAdapter adapter) => MapTileCache(
      resolveDirectory: () async => tmp,
      httpClientAdapter: adapter,
    );

    test('sin path_provider no hace nada y no falla', () async {
      final adapter = FakeTileAdapter();
      await prefetchRouteTiles(
        [laPaz],
        cache: MapTileCache(httpClientAdapter: adapter),
        startDelay: Duration.zero,
      );
      expect(adapter.requests, isEmpty);
    });

    test('la API por defecto (instancia global) no rompe en tests', () async {
      await prefetchRouteTiles([laPaz], startDelay: Duration.zero);
    });

    test('baja todos los tiles una vez y no repite los guardados', () async {
      final adapter = FakeTileAdapter();
      final cache = cacheWith(adapter);
      final expected = computeRouteTiles([laPaz]).length;

      await prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests, hasLength(expected));
      expect(
        adapter.requests.first.toString(),
        startsWith('https://tile.openstreetmap.org/13/'),
      );

      await prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests, hasLength(expected));
      await cache.trim();
    });

    test('respeta el tope y la concurrencia', () async {
      final adapter = FakeTileAdapter(delay: const Duration(milliseconds: 5));
      final cache = cacheWith(adapter);

      await prefetchRouteTiles(
        [laPaz, santaCruz],
        maxTiles: 12,
        cache: cache,
        startDelay: Duration.zero,
      );

      expect(adapter.requests, hasLength(12));
      expect(adapter.maxInFlight, lessThanOrEqualTo(kPrefetchConcurrency));
      await cache.trim();
    });

    test('zoom máximo acotado al zoom nativo del mapa', () async {
      final adapter = FakeTileAdapter();
      final cache = cacheWith(adapter);
      await prefetchRouteTiles(
        [laPaz],
        minZoom: 18,
        maxZoom: 22,
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests, isNotEmpty);
      expect(
        adapter.requests.every((u) => u.pathSegments.first == '18'),
        isTrue,
      );
      await cache.trim();
    });

    test('se puede cancelar', () async {
      final adapter = FakeTileAdapter(delay: const Duration(milliseconds: 20));
      final cache = cacheWith(adapter);
      final total = computeRouteTiles([laPaz]).length;

      final running = prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cancelRouteTilePrefetch();
      await running;

      expect(adapter.requests.length, lessThan(total));
      await cache.trim();
    });

    test('una nueva precarga cancela la anterior', () async {
      final adapter = FakeTileAdapter(delay: const Duration(milliseconds: 20));
      final cache = cacheWith(adapter);
      final total = computeRouteTiles([laPaz]).length;

      final first = prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final second = prefetchRouteTiles(
        [santaCruz],
        maxTiles: 1,
        cache: cache,
        startDelay: Duration.zero,
      );
      await Future.wait([first, second]);

      final toLaPaz = adapter.requests
          .where((u) => u.pathSegments[1].startsWith('25'))
          .length;
      expect(toLaPaz, lessThan(total));
      await cache.trim();
    });

    test('sin señal: abandona tras pocos errores seguidos', () async {
      final adapter = FakeTileAdapter(fail: true);
      final cache = cacheWith(adapter);

      await prefetchRouteTiles(
        [laPaz, santaCruz],
        cache: cache,
        startDelay: Duration.zero,
      );

      // 5 errores seguidos (una sola descarga a la vez).
      expect(adapter.requests.length, lessThanOrEqualTo(5));
      await cache.trim();
    });

    test('sin señal no cuenta como hecha: se reintenta la próxima', () async {
      final adapter = FakeTileAdapter(fail: true);
      final cache = cacheWith(adapter);

      await prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );
      final first = adapter.requests.length;
      await prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );

      expect(adapter.requests.length, greaterThan(first));
    });
  });

  group('prefetchRouteTiles — no compite con el mapa visible', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('map_prefetch_once');
    });

    tearDown(() async {
      cancelRouteTilePrefetch();
      await _deleteQuietly(tmp);
    });

    MapTileCache cacheWith(FakeTileAdapter adapter) => MapTileCache(
      resolveDirectory: () async => tmp,
      httpClientAdapter: adapter,
    );

    test('una sola vez por ruta en la sesión (ni chequea el disco)', () async {
      final adapter = FakeTileAdapter();
      final cache = cacheWith(adapter);
      final expected = computeRouteTiles([laPaz]).length;

      await prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests, hasLength(expected));

      // Se borra la caché de disco: si la precarga se repitiera, volvería a
      // bajar todo. Memoizada por ruta, no hace nada.
      for (final entity in tmp.listSync()) {
        entity.deleteSync(recursive: true);
      }
      await prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests, hasLength(expected));

      // Otra ruta sí se precarga.
      await prefetchRouteTiles(
        [santaCruz],
        maxTiles: 3,
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests, hasLength(expected + 3));

      // Tras olvidar la memoria, la misma ruta vuelve a bajarse.
      resetRouteTilePrefetchMemo(cache);
      await prefetchRouteTiles(
        [laPaz],
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests.length, greaterThan(expected + 3));
    });

    test('routeKey explícito memoiza aunque cambien los puntos', () async {
      final adapter = FakeTileAdapter();
      final cache = cacheWith(adapter);

      await prefetchRouteTiles(
        [laPaz],
        maxTiles: 2,
        routeKey: 'ruta-1',
        cache: cache,
        startDelay: Duration.zero,
      );
      await prefetchRouteTiles(
        [santaCruz],
        maxTiles: 2,
        routeKey: 'ruta-1',
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests, hasLength(2));
    });

    test('la misma ruta en curso devuelve la misma precarga', () async {
      final adapter = FakeTileAdapter(delay: const Duration(milliseconds: 5));
      final cache = cacheWith(adapter);

      final a = prefetchRouteTiles(
        [laPaz],
        maxTiles: 4,
        cache: cache,
        startDelay: Duration.zero,
      );
      final b = prefetchRouteTiles(
        [laPaz],
        maxTiles: 4,
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(identical(a, b), isTrue);
      await Future.wait([a, b]);
      expect(adapter.requests, hasLength(4));
    });

    test('arranque diferido: nada se pide antes de startDelay', () async {
      final adapter = FakeTileAdapter();
      final cache = cacheWith(adapter);

      final running = prefetchRouteTiles(
        [laPaz],
        maxTiles: 3,
        cache: cache,
        startDelay: const Duration(milliseconds: 300),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(adapter.requests, isEmpty);
      await running;
      expect(adapter.requests, hasLength(3));
    });

    test('cancelar durante la espera inicial no pide nada', () async {
      final adapter = FakeTileAdapter();
      final cache = cacheWith(adapter);

      final running = prefetchRouteTiles(
        [laPaz],
        maxTiles: 3,
        cache: cache,
        startDelay: const Duration(seconds: 30),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      cancelRouteTilePrefetch();
      await running.timeout(const Duration(seconds: 2));
      expect(adapter.requests, isEmpty);
    });

    test('el default arranca diferido (kPrefetchStartDelay)', () async {
      final adapter = FakeTileAdapter();
      final cache = cacheWith(adapter);

      unawaited(prefetchRouteTiles([laPaz], maxTiles: 2, cache: cache));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(adapter.requests, isEmpty);
      cancelRouteTilePrefetch();
    });
  });

  group('tope por zoom', () {
    test('ningún zoom pasa de maxTilesPerZoom', () {
      final tiles = computeRouteTiles(
        [laPaz, santaCruz],
        minZoom: 13,
        maxZoom: 16,
        maxTiles: 1000,
        maxTilesPerZoom: 50,
      );
      for (var z = 13; z <= 16; z++) {
        expect(tiles.where((t) => t.z == z).length, lessThanOrEqualTo(50));
      }
      // El zoom alto no se come el tope: hay tiles de los cuatro zooms.
      expect(tiles.map((t) => t.z).toSet(), {13, 14, 15, 16});
    });

    test('tope por zoom por defecto menor que el total', () {
      expect(kPrefetchMaxTilesPerZoom, lessThan(kPrefetchMaxTiles));
    });

    test('la precarga respeta el tope por zoom', () async {
      final tmp = await Directory.systemTemp.createTemp('map_prefetch_zoom');
      addTearDown(() => tmp.delete(recursive: true));
      final adapter = FakeTileAdapter();
      final cache = MapTileCache(
        resolveDirectory: () async => tmp,
        httpClientAdapter: adapter,
      );
      await prefetchRouteTiles(
        [laPaz, santaCruz],
        minZoom: 15,
        maxZoom: 15,
        maxTilesPerZoom: 7,
        cache: cache,
        startDelay: Duration.zero,
      );
      expect(adapter.requests, hasLength(7));
      await cache.trim();
    });
  });
}
