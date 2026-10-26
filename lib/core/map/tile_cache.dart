import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Identificador del paquete usado como User-Agent al pedir tiles.
///
/// Los servidores de tiles de OSM exigen un User-Agent propio que identifique
/// la app (tile usage policy); se comparte desde acá para que el mapa y la
/// precarga lo usen igual.
const String kMapUserAgentPackageName = 'bo.com.dismac.logistics_app';

/// User-Agent completo que se manda con cada tile (mapa y precarga).
const String kMapUserAgent = 'flutter_map ($kMapUserAgentPackageName)';

/// Subcarpeta de `getApplicationSupportDirectory()` donde viven los tiles.
const String kMapTileCacheFolder = 'map_tiles';

/// Tope de disco de la caché de tiles. Un tile OSM pesa ~10–25 KB: 150 MB son
/// ~7 000–10 000 tiles, de sobra para la zona de trabajo de un chofer, y poco
/// para un teléfono de 16 GB.
const int kMapTileCacheMaxBytes = 150 * 1024 * 1024;

/// Al pasarse del tope se borra hasta quedar en este tamaño (histéresis: así
/// no se limpia de a un tile cada vez).
const int kMapTileCacheTargetBytes = 120 * 1024 * 1024;

/// Antigüedad máxima de un tile en disco. Pasado este tiempo se borra y se
/// vuelve a bajar la próxima vez que se vea con señal.
const Duration kMapTileCacheMaxAge = Duration(days: 30);

/// Cada cuántos tiles nuevos bajados de la red se programa una limpieza.
const int _trimEveryNewTiles = 300;

/// Conexiones simultáneas al servidor de tiles. Sin tope, `dart:io` abre una
/// por tile pedido (decenas al hacer zoom): sockets, buffers y CPU que en un
/// teléfono de 1 GB compiten con la cámara. 4 alcanza para llenar la pantalla
/// rápido y respeta el espíritu de la tile usage policy de OSM.
const int kMapTileMaxConnections = 4;

/// Una conexión ociosa se cierra pasado este tiempo (libera el socket y sus
/// buffers cuando el chofer deja de mover el mapa).
const Duration kMapTileIdleTimeout = Duration(seconds: 15);

/// Caché persistente en disco de los tiles del mapa (zonas sin señal).
///
/// Política "caché primero": si el tile está en disco se sirve de ahí sin tocar
/// la red (instantáneo y sin datos); si no está, se baja y se guarda. La
/// frescura la da la limpieza por antigüedad ([kMapTileCacheMaxAge]): un tile
/// de más de 30 días se borra y se vuelve a bajar. El tamaño se acota a
/// [kMapTileCacheMaxBytes] borrando primero los tiles más viejos.
///
/// Usa un único cliente [Dio] compartido por todos los mapas y la precarga
/// (no se crea un cliente HTTP por mapa).
///
/// Si no hay carpeta de la app (tests sin `path_provider`, web) la caché queda
/// deshabilitada y los tiles se piden a la red como antes, sin errores.
///
/// En `flutter test` la instancia global arranca deshabilitada (variable de
/// entorno `FLUTTER_TEST`): así los tests de widgets con mapas siguen usando
/// el `NetworkTileProvider` de siempre (Dio deja timers pendientes en el
/// reloj falso de `testWidgets`).
class MapTileCache {
  /// [resolveDirectory] devuelve la carpeta de la caché (o `null` = sin caché);
  /// por defecto `getApplicationSupportDirectory()/map_tiles`.
  /// [httpClientAdapter] permite inyectar un adaptador falso en tests.
  /// [enabled] en `false` la deja deshabilitada desde el arranque.
  MapTileCache({
    bool enabled = true,
    Future<Directory?> Function()? resolveDirectory,
    HttpClientAdapter? httpClientAdapter,
    this.maxBytes = kMapTileCacheMaxBytes,
    this.targetBytes = kMapTileCacheTargetBytes,
    this.maxAge = kMapTileCacheMaxAge,
  }) : _disabled = !enabled || kIsWeb,
       _resolveDirectory = resolveDirectory ?? _defaultDirectory,
       _httpClientAdapter = httpClientAdapter;

  /// Instancia global que usan `OsmTileLayer` y la precarga.
  static final MapTileCache instance = MapTileCache(
    enabled: !_runningFlutterTest(),
  );

  static bool _runningFlutterTest() {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  bool _disabled;

  /// `true` cuando ya se sabe que no hay caché (deshabilitada o sin carpeta):
  /// los mapas piden los tiles a la red directamente.
  bool get isDisabled => _disabled;

  final Future<Directory?> Function() _resolveDirectory;
  final HttpClientAdapter? _httpClientAdapter;
  final int maxBytes;
  final int targetBytes;
  final Duration maxAge;

  Future<_OpenedStore?>? _opened;
  late final _DeferredCacheStore _store = _DeferredCacheStore(
    () => _open().then((opened) => opened?.store),
  );
  late final Dio dio = _createDio();

  int _newTilesSinceTrim = 0;
  Future<void>? _trimming;

  /// Encabezados que se mandan con cada tile.
  static const Map<String, String> headers = {'User-Agent': kMapUserAgent};

  /// Store de la caché; `null` si la caché está deshabilitada.
  Future<CacheStore?> get store => _open().then((opened) => opened?.store);

  /// Carpeta de la caché; `null` si la caché está deshabilitada.
  Future<Directory?> get directory =>
      _open().then((opened) => opened?.directory);

  /// Clave con la que se guarda en disco el tile de [url].
  static String cacheKeyFor(String url) =>
      CacheOptions.defaultCacheKeyBuilder(url: Uri.parse(url));

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        headers: headers,
        responseType: ResponseType.bytes,
        // Con señal débil un tile colgado no debe quedar ocupando conexión.
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    dio.httpClientAdapter =
        _httpClientAdapter ??
        IOHttpClientAdapter(
          createHttpClient: () => HttpClient()
            ..maxConnectionsPerHost = kMapTileMaxConnections
            ..idleTimeout = kMapTileIdleTimeout,
        );
    dio.interceptors.addAll([
      DioCacheInterceptor(
        options: CacheOptions(
          store: _store,
          // Caché primero: si está en disco, no se pide a la red.
          policy: CachePolicy.forceCache,
          // Sin maxStale: así un acierto no reescribe el archivo y la fecha de
          // modificación queda como fecha de descarga (la usa la limpieza).
          hitCacheOnNetworkFailure: true,
          hitCacheOnErrorCodes: const [404, 429, 500, 502, 503, 504],
        ),
      ),
      InterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.extra[extraFromNetworkKey] == true) {
            _onNewTileStored();
          }
          handler.next(response);
        },
      ),
    ]);
    return dio;
  }

  Future<_OpenedStore?> _open() => _opened ??= _openStore();

  Future<_OpenedStore?> _openStore() async {
    if (_disabled) {
      return null;
    }
    try {
      final dir = await _resolveDirectory();
      if (dir == null) {
        _disabled = true;
        return null;
      }
      await dir.create(recursive: true);
      final opened = _OpenedStore(dir, _TileFileStore(dir.path));
      // Limpieza inicial en segundo plano (no bloquea el primer tile).
      unawaited(trim());
      return opened;
    } catch (error) {
      // Sin path_provider (tests) o sin permiso de disco: red sin caché.
      debugPrint('Caché de tiles deshabilitada (${error.runtimeType}).');
      _disabled = true;
      return null;
    }
  }

  static Future<Directory?> _defaultDirectory() async {
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, kMapTileCacheFolder));
  }

  void _onNewTileStored() {
    _newTilesSinceTrim++;
    if (_newTilesSinceTrim >= _trimEveryNewTiles) {
      _newTilesSinceTrim = 0;
      unawaited(trim());
    }
  }

  /// Borra tiles vencidos y, si la caché pasa el tope, los más viejos.
  ///
  /// Corre en un isolate aparte (solo `stat`/`delete`, nunca lee los tiles) y
  /// no se solapa: si ya hay una limpieza en curso devuelve esa.
  Future<void> trim() {
    return _trimming ??= _runTrim().whenComplete(() => _trimming = null);
  }

  Future<void> _runTrim() async {
    final dir = await directory;
    if (dir == null) {
      return;
    }
    final path = dir.path;
    final maxBytes = this.maxBytes;
    final targetBytes = this.targetBytes;
    final maxAge = this.maxAge;
    try {
      await Isolate.run(
        () => trimTileCacheDirectory(
          path,
          maxBytes: maxBytes,
          targetBytes: targetBytes,
          maxAge: maxAge,
        ),
      );
    } catch (error) {
      debugPrint('No se pudo limpiar la caché de tiles: $error');
    }
  }
}

class _OpenedStore {
  const _OpenedStore(this.directory, this.store);

  final Directory directory;
  final CacheStore store;
}

/// Resultado de [trimTileCacheDirectory].
class TileCacheTrimResult {
  const TileCacheTrimResult({
    required this.deletedFiles,
    required this.remainingBytes,
  });

  final int deletedFiles;
  final int remainingBytes;
}

/// Limpia la carpeta de la caché de tiles (síncrona: se corre en un isolate).
///
/// 1. Borra los archivos con fecha de modificación (= fecha de descarga) más
///    vieja que [maxAge].
/// 2. Si lo que queda pesa más de [maxBytes], borra del más viejo al más nuevo
///    hasta bajar a [targetBytes].
TileCacheTrimResult trimTileCacheDirectory(
  String path, {
  int maxBytes = kMapTileCacheMaxBytes,
  int targetBytes = kMapTileCacheTargetBytes,
  Duration maxAge = kMapTileCacheMaxAge,
  DateTime? now,
}) {
  final dir = Directory(path);
  if (!dir.existsSync()) {
    return const TileCacheTrimResult(deletedFiles: 0, remainingBytes: 0);
  }
  final limit = (now ?? DateTime.now()).subtract(maxAge);
  final entries = <(File, int, DateTime)>[];
  var deleted = 0;
  var total = 0;

  bool tryDelete(File file) {
    try {
      file.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final FileStat stat;
    try {
      stat = entity.statSync();
    } catch (_) {
      continue;
    }
    if (stat.modified.isBefore(limit)) {
      if (tryDelete(entity)) {
        deleted++;
        continue;
      }
    }
    entries.add((entity, stat.size, stat.modified));
    total += stat.size;
  }

  if (total > maxBytes) {
    entries.sort((a, b) => a.$3.compareTo(b.$3));
    for (final (file, size, _) in entries) {
      if (total <= targetBytes) {
        break;
      }
      if (tryDelete(file)) {
        deleted++;
        total -= size;
      }
    }
  }
  return TileCacheTrimResult(deletedFiles: deleted, remainingBytes: total);
}

/// Store en disco que no hace la limpieza inicial de [FileCacheStore].
///
/// `FileCacheStore` al crearse lee y deserializa TODOS los archivos para
/// borrar los vencidos: con miles de tiles eso es leer ~150 MB al abrir el
/// mapa en un teléfono barato. La limpieza propia ([trimTileCacheDirectory])
/// solo mira fecha y tamaño.
class _TileFileStore extends FileCacheStore {
  _TileFileStore(super.directory);

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) async {
    if (staleOnly) {
      return;
    }
    return super.clean(priorityOrBelow: priorityOrBelow, staleOnly: staleOnly);
  }
}

/// Store que espera a que la carpeta esté disponible; sin carpeta se comporta
/// como una caché vacía (todo va a la red y nada se guarda).
class _DeferredCacheStore extends CacheStore {
  _DeferredCacheStore(this._resolve);

  final Future<CacheStore?> Function() _resolve;

  @override
  Future<void> clean({
    CachePriority priorityOrBelow = CachePriority.high,
    bool staleOnly = false,
  }) async => (await _resolve())?.clean(
    priorityOrBelow: priorityOrBelow,
    staleOnly: staleOnly,
  );

  @override
  Future<void> close() async => (await _resolve())?.close();

  @override
  Future<void> delete(String key, {bool staleOnly = false}) async =>
      (await _resolve())?.delete(key, staleOnly: staleOnly);

  @override
  Future<void> deleteFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async =>
      (await _resolve())?.deleteFromPath(pathPattern, queryParams: queryParams);

  @override
  Future<bool> exists(String key) async =>
      await (await _resolve())?.exists(key) ?? false;

  @override
  Future<CacheResponse?> get(String key) async => (await _resolve())?.get(key);

  @override
  Future<List<CacheResponse>> getFromPath(
    RegExp pathPattern, {
    Map<String, String?>? queryParams,
  }) async =>
      await (await _resolve())?.getFromPath(
        pathPattern,
        queryParams: queryParams,
      ) ??
      const [];

  @override
  Future<void> set(CacheResponse response) async =>
      (await _resolve())?.set(response);
}

/// Tile provider con caché en disco que comparte el [Dio] de [MapTileCache].
///
/// A diferencia de `CachedTileProvider` (flutter_map_cache), no crea un cliente
/// ni un interceptor por mapa: todos los mapas usan el mismo. Al descartarse
/// la capa no se cierra el cliente compartido. Cada tile se carga con
/// [CachedTileImageProvider].
///
/// Si la caché está deshabilitada ([MapTileCache.isDisabled]) delega en un
/// `NetworkTileProvider` común (se crea solo en ese caso).
class CachedOsmTileProvider extends TileProvider {
  CachedOsmTileProvider({MapTileCache? cache})
    : cache = cache ?? MapTileCache.instance,
      super(headers: Map<String, String>.of(MapTileCache.headers));

  final MapTileCache cache;

  NetworkTileProvider? _network;

  @override
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    if (cache.isDisabled) {
      final network = _network ??= NetworkTileProvider(headers: headers);
      return network.getImage(coordinates, options);
    }
    return CachedTileImageProvider(
      dio: cache.dio,
      url: getTileUrl(coordinates, options),
      fallbackUrl: getTileFallbackUrl(coordinates, options),
      headers: headers,
      cancelLoading: cancelLoading,
    );
  }

  @override
  void dispose() {
    // El Dio es compartido: no se cierra. El cliente de red, si se creó, sí.
    _network?.dispose();
    _network = null;
    super.dispose();
  }
}

/// Error compacto de un tile que no se pudo cargar (sin señal y sin copia en
/// disco, o error HTTP).
///
/// flutter_map imprime cada error de tile con `debugPrint`: sin señal son
/// decenas por minuto. Un `DioException` completo (opciones, cabeceras, causa)
/// pesa varios KB de texto por tile; este es una línea.
class TileLoadException implements Exception {
  const TileLoadException(this.url, {this.statusCode});

  final String url;

  /// Código HTTP si el servidor respondió; `null` = sin red.
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'Tile sin señal: $url'
      : 'Tile HTTP $statusCode: $url';
}

/// Imagen de un tile servida por el [Dio] compartido (caché en disco primero).
///
/// Reemplaza al `CachedImageProvider` de flutter_map_cache, afinado para gama
/// baja:
/// - No copia los bytes (`Uint8List.fromList`) si ya llegan como `Uint8List`.
/// - No emite eventos de progreso por tile (ni deja abierto su stream).
/// - Al descartarse el tile (`cancelLoading`, también tras cargar bien) corta
///   la descarga en curso y saca la imagen de la `ImageCache` global: la clave
///   es la instancia, así que nadie la vuelve a usar y solo ocuparía lugar
///   (256 KB decodificados por tile) desplazando fotos y tiles visibles.
/// - Los errores salen como [TileLoadException] (una línea, sin stack de Dio).
class CachedTileImageProvider extends ImageProvider<CachedTileImageProvider> {
  CachedTileImageProvider({
    required this.dio,
    required this.url,
    required this.headers,
    required Future<void> cancelLoading,
    this.fallbackUrl,
  }) {
    cancelLoading.then((_) => _release(), onError: (Object _) => _release());
  }

  final Dio dio;
  final String url;
  final String? fallbackUrl;
  final Map<String, String> headers;

  final CancelToken _cancelToken = CancelToken();

  void _release() {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel('tile descartado');
    }
    try {
      PaintingBinding.instance.imageCache.evict(this);
    } catch (_) {
      // Sin binding (tests de unidad): no hay caché de imágenes que limpiar.
    }
  }

  @override
  Future<CachedTileImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<CachedTileImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(
    CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _decode(decode),
      scale: 1,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _decode(ImageDecoderCallback decode) async {
    final bytes = await fetchBytes();
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  /// Bytes del tile (disco o red). Si la capa ya no lo necesita devuelve un
  /// PNG transparente; si no hay ni red ni copia lanza [TileLoadException].
  @visibleForTesting
  Future<Uint8List> fetchBytes({bool useFallback = false}) async {
    final target = useFallback ? fallbackUrl! : url;
    try {
      final response = await dio.get<List<int>>(
        target,
        cancelToken: _cancelToken,
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw TileLoadException(target, statusCode: response.statusCode);
      }
      return data is Uint8List ? data : Uint8List.fromList(data);
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) {
        return TileProvider.transparentImage;
      }
      if (!useFallback && fallbackUrl != null) {
        return fetchBytes(useFallback: true);
      }
      throw TileLoadException(target, statusCode: error.response?.statusCode);
    }
  }
}
