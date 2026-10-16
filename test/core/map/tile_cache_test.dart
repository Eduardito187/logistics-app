import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/map/osm_tile_layer.dart';
import 'package:logistics_app/core/map/tile_cache.dart';

import 'support/fake_tile_adapter.dart';

// Caché de tiles en disco (zonas sin señal): caché primero, cae a red sin
// caché cuando no hay carpeta de la app, y limpieza por antigüedad y tamaño.
void main() {
  const url = 'https://tile.openstreetmap.org/13/2545/4476.png';

  Future<List<int>?> getTile(MapTileCache cache) async {
    final response = await cache.dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  group('sin path_provider (tests / web)', () {
    test('la caché queda deshabilitada y los tiles van a la red', () async {
      final adapter = FakeTileAdapter();
      // Directorio por defecto: getApplicationSupportDirectory() falla en test.
      final cache = MapTileCache(httpClientAdapter: adapter);

      expect(await cache.store, isNull);
      expect(await getTile(cache), hasLength(64));
      expect(await getTile(cache), hasLength(64));
      // Sin caché, cada pedido sale a la red.
      expect(adapter.requests, hasLength(2));
    });

    test('la instancia global arranca deshabilitada en flutter test', () async {
      // Así los testWidgets con mapas siguen con el NetworkTileProvider.
      expect(MapTileCache.instance.isDisabled, isTrue);
      expect(await MapTileCache.instance.store, isNull);
    });

    test('sin path_provider queda marcada como deshabilitada', () async {
      final cache = MapTileCache(httpClientAdapter: FakeTileAdapter());
      expect(cache.isDisabled, isFalse); // todavía no se sabe
      await cache.store;
      expect(cache.isDisabled, isTrue);
    });

    test('carpeta nula = sin caché, sin errores', () async {
      final adapter = FakeTileAdapter();
      final cache = MapTileCache(
        resolveDirectory: () async => null,
        httpClientAdapter: adapter,
      );
      expect(await cache.directory, isNull);
      expect(await getTile(cache), hasLength(64));
      await cache.trim(); // no hace nada
    });
  });

  group('con carpeta', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('map_tiles_test');
    });

    tearDown(() async {
      if (tmp.existsSync()) {
        await tmp.delete(recursive: true);
      }
    });

    test('guarda el tile y después lo sirve sin red', () async {
      final adapter = FakeTileAdapter();
      final cache = MapTileCache(
        resolveDirectory: () async => tmp,
        httpClientAdapter: adapter,
      );

      expect(await getTile(cache), hasLength(64));
      expect(adapter.requests, hasLength(1));
      expect(
        await (await cache.store)!.exists(MapTileCache.cacheKeyFor(url)),
        isTrue,
      );

      // Sin señal: el tile sale del disco, sin pedirlo a la red.
      adapter.fail = true;
      expect(await getTile(cache), hasLength(64));
      expect(adapter.requests, hasLength(1));
      await cache.trim();
    });

    test('manda el User-Agent propio de la app (política de OSM)', () async {
      final adapter = FakeTileAdapter();
      final cache = MapTileCache(
        resolveDirectory: () async => tmp,
        httpClientAdapter: adapter,
      );
      await getTile(cache);
      expect(
        adapter.requestHeaders.single['User-Agent'],
        'flutter_map (bo.com.dismac.logistics_app)',
      );
      await cache.trim();
    });

    test('sin señal y sin tile guardado: error normal, no cuelga', () async {
      final cache = MapTileCache(
        resolveDirectory: () async => tmp,
        httpClientAdapter: FakeTileAdapter(fail: true),
      );
      await expectLater(getTile(cache), throwsA(isA<DioException>()));
      await cache.trim();
    });
  });

  group('trimTileCacheDirectory', () {
    late Directory tmp;
    final now = DateTime(2026, 10, 16, 12);

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('map_tiles_trim');
    });

    tearDown(() async {
      if (tmp.existsSync()) {
        await tmp.delete(recursive: true);
      }
    });

    File tile(String name, int bytes, DateTime modified) {
      final file = File('${tmp.path}/normal/$name')
        ..createSync(recursive: true)
        ..writeAsBytesSync(List<int>.filled(bytes, 1));
      file.setLastModifiedSync(modified);
      return file;
    }

    test('borra los tiles de más de 30 días', () {
      final old = tile('old', 10, now.subtract(const Duration(days: 31)));
      final fresh = tile('fresh', 10, now.subtract(const Duration(days: 2)));

      final result = trimTileCacheDirectory(tmp.path, now: now);

      expect(result.deletedFiles, 1);
      expect(old.existsSync(), isFalse);
      expect(fresh.existsSync(), isTrue);
      expect(result.remainingBytes, 10);
    });

    test('pasado el tope borra los más viejos hasta el objetivo', () {
      final a = tile('a', 100, now.subtract(const Duration(days: 5)));
      final b = tile('b', 100, now.subtract(const Duration(days: 4)));
      final c = tile('c', 100, now.subtract(const Duration(days: 3)));
      final d = tile('d', 100, now.subtract(const Duration(days: 1)));

      final result = trimTileCacheDirectory(
        tmp.path,
        maxBytes: 350,
        targetBytes: 200,
        now: now,
      );

      expect(result.deletedFiles, 2);
      expect(result.remainingBytes, 200);
      expect(a.existsSync(), isFalse);
      expect(b.existsSync(), isFalse);
      expect(c.existsSync(), isTrue);
      expect(d.existsSync(), isTrue);
    });

    test('bajo el tope no borra nada', () {
      tile('a', 100, now);
      final result = trimTileCacheDirectory(tmp.path, maxBytes: 1000, now: now);
      expect(result.deletedFiles, 0);
    });

    test('carpeta inexistente: no falla', () {
      final result = trimTileCacheDirectory('${tmp.path}/no_existe');
      expect(result.deletedFiles, 0);
    });

    test('topes por defecto pensados para teléfonos de 16 GB', () {
      expect(kMapTileCacheMaxBytes, 150 * 1024 * 1024);
      expect(kMapTileCacheTargetBytes, lessThan(kMapTileCacheMaxBytes));
      expect(kMapTileCacheMaxAge, const Duration(days: 30));
    });
  });

  group('integración con la capa de tiles', () {
    test('buildOsmTileLayer usa el provider con caché', () {
      final layer = buildOsmTileLayer();
      expect(layer.tileProvider, isA<CachedOsmTileProvider>());
      expect(layer.tileProvider.headers['User-Agent'], kMapUserAgent);
    });

    test('todas las capas comparten un único cliente HTTP', () {
      final a = buildOsmTileLayer().tileProvider as CachedOsmTileProvider;
      final b = buildOsmTileLayer().tileProvider as CachedOsmTileProvider;
      expect(identical(a.cache.dio, b.cache.dio), isTrue);
      expect(identical(a.cache, MapTileCache.instance), isTrue);
    });
  });
}
