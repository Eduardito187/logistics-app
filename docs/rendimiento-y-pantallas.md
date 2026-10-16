# Rendimiento y tamaños de pantalla

Objetivo: que la app ande fluida en teléfonos de **1 GB de RAM** (Android Go / gama baja) y se vea
bien desde un teléfono chico (320 dp de ancho) hasta una tablet en horizontal. Este documento junta
las decisiones y cómo verificarlas.

## Presupuesto de memoria

En un teléfono de 1 GB el sistema deja ~250–350 MB para la app en primer plano. Lo que más consume,
en orden: cámara (escáner), tiles del mapa, imágenes decodificadas, base local. Las decisiones:

| Área | Decisión | Dónde | Impacto esperado |
|---|---|---|---|
| Caché de imágenes | 40 MB / 80 imágenes (default 100 MB / 1000) | `lib/main.dart` | −60 MB de techo |
| Mapa | sin retina, `keepBuffer` 1, `panBuffer` 0, `maxNativeZoom` 18, sin fundido | `lib/core/map/osm_tile_layer.dart` | ~½ de tiles vivos al panear; 4x menos que retina |
| Mapa | `OsmTileLayer` (const) crea la capa una sola vez | idem | no deja clientes HTTP sin cerrar al reconstruir |
| Escáner | 1280x720, análisis cada 250 ms, `returnImage: false` | `lib/core/scanning/scanner_screen.dart` | ~4 análisis/seg en vez de ~30; sin copiar cuadros a Dart |
| Escáner | cámara se suelta al minimizar la app y al leer el código | idem | el sistema no mata la app por retener la cámara |
| Cola offline | `watchQueue` sin la columna `payload` y con tope de 200 filas | `lib/core/offline/app_database.dart` | la pantalla de sync no carga los JSON de cada escaneo |
| Cola offline | drenado por lotes de 25, sin drenados solapados | `lib/core/offline/offline_queue.dart` | memoria acotada aunque haya días de escaneos sin señal |
| Cola offline | `pendingCount` con `COUNT(*)`; índices `(status, id)` y `created_at` | idem | consultas O(log n), sin traer filas |
| Fotos | se suben en streaming desde disco (`MultipartFile.fromFileSync`) | `photo_upload_queue.dart` | la foto nunca está entera en memoria |
| GPS | intervalo mínimo 10 s (Android) + filtro 20 m; 1 posición encolada cada ≥10 s | `lib/core/location/` | ~360 POST/h en vez de ~3000 a 60 km/h; menos batería |
| Tema | `ThemeData` armado una sola vez; `InkRipple` en vez de `InkSparkle` | `lib/core/theme/app_theme.dart` | sin recalcular la paleta; sin shader en el primer toque |
| Spinners | `RepaintBoundary` alrededor del indicador (`LoadingView`) | `lib/core/widgets/async_value_view.dart` | la animación no repinta toda la pantalla |

### `largeHeap`: no se pide

`android:largeHeap` solo agranda el heap de **Java/ART**. La memoria de Flutter (heap de Dart,
imágenes, GPU) es nativa y no la toca. En equipos Android Go además `largeHeap` suele valer lo
mismo que el heap normal, y en el resto hace que el sistema mate primero a la app cuando falta RAM.
No hay código Java pesado en la app, así que no hay motivo para pedirlo.

`android:hardwareAccelerated="true"` está explícito en la actividad (es el default desde API 14; se
deja para que nadie lo apague por error).

## Build de Android

### R8 / shrinkResources

`android/app/build.gradle.kts` (release): `isMinifyEnabled = true` + `isShrinkResources = true`.
Quita el código Java/Kotlin de los plugins que no se usa (menos DEX que cargar al arrancar) y los
recursos sin referencia.

- Reglas propias: `android/app/proguard-rules.pro` (Gson de `flutter_local_notifications`,
  `flutter_foreground_task`, `flutter_blue_plus`, `usb_serial`/felHR85 por reflexión, ML Kit,
  Play Core de Flutter). Firebase y mobile_scanner traen además sus reglas "consumer".
- Recursos usados **por nombre** desde Dart (p. ej. `@mipmap/ic_launcher` como ícono de las
  notificaciones locales) se conservan en `android/app/src/main/res/raw/keep.xml`.
- Si al agregar un plugin la release crashea con `ClassNotFoundException` / `NoSuchMethodError` y
  la debug no, falta una regla `-keep` para ese plugin.

### APK por arquitectura (`--split-per-abi`)

```
flutter build apk --release --split-per-abi --dart-define-from-file=config/dev.json
# o: make apk ENV=staging
```

Genera un APK por ABI en `build/app/outputs/flutter-apk/`:

- `app-armeabi-v7a-release.apk` — la mayoría de los Android Go / 1 GB (32 bits).
- `app-arm64-v8a-release.apk` — el resto de los teléfonos y tablets.
- `app-x86_64-release.apk` — emulador.

Cada uno pesa ~⅓ del APK "universal" (que trae el motor de Flutter y las librerías nativas de las
tres ABIs). Para Play Store se sube un App Bundle (`flutter build appbundle`), que ya reparte por
ABI solo. Para distribución interna (MDM, enlace) se reparte el APK de la ABI del equipo.

## Pantallas: de teléfono chico a tablet

- Puntos de corte compartidos: `lib/core/layout/breakpoints.dart` (compact < 600 ≤ medium < 840 ≤
  expanded) y `responsive_body.dart` (ancho máximo de contenido en tablet).
- Letra del sistema: se respeta pero con tope **1.3x** (`app.dart`).
- Objetivos táctiles: **≥ 48 dp** siempre (densidad visual estándar, `MaterialTapTargetSize.padded`,
  `IconButton`/`TextButton` con mínimo 48x48, `ListTile` de 56). Botones principales de **56 dp**
  (`AppTheme.primaryButtonHeight`). Se usa con guantes.
- Recuadro del escáner: 260 dp como máximo, se achica en pantallas angostas o en horizontal
  (`ScanFrame.sideFor`).
- `StatTile`: el número se achica (FittedBox) en vez de desbordar en mosaicos angostos.

### Cómo probar tamaños

`test/support/screen_sizes.dart` define `TestScreen` (smallPhone 320x568, phone 360x780,
tabletPortrait 800x1280, tabletLandscape 1280x800) y:

```dart
testOnScreens('mi pantalla no se desborda', (tester, screen) async {
  await tester.pumpWidget(MaterialApp(home: withTextScale(const MiPantalla())));
  expect(tester.takeException(), isNull); // un overflow hace fallar el test
});
```

`withTextScale` simula la letra grande del sistema (1.3x por defecto). Un "RenderFlex overflowed"
en cualquiera de los tamaños hace fallar el test.

### Cómo medir en un equipo real

- `flutter run --profile` en un teléfono de gama baja y abrir DevTools → *Memory* / *Performance*.
- `adb shell dumpsys meminfo bo.com.dismac.logistics_app` para el total (PSS) del proceso.
- Recorrido mínimo: login → mapa de ruta (panear/zoom) → escáner → foto de evidencia → sync. Con la
  cámara abierta el total no debería pasar de ~250 MB.

## Pendientes para las features

- Listas largas: usar `ListView.builder` (la pantalla de sincronización arma la lista entera con
  `ListView(children: [...])`).
- Mapas: usar `const OsmTileLayer()` en vez de `buildOsmTileLayer()` dentro de `build` cuando el
  widget se reconstruye seguido (p. ej. el mapa de flota que recibe posiciones en vivo).

## Mapas sin señal

En zonas sin cobertura el chofer veía el mapa gris: los tiles se pedían siempre a la red. Ahora
se guardan en disco (`lib/core/map/tile_cache.dart`) y se pueden precargar
(`lib/core/map/tile_prefetch.dart`).

### Caché de tiles en disco

- **Dónde:** `getApplicationSupportDirectory()/map_tiles` (flutter_map_cache +
  dio_cache_interceptor + http_cache_file_store). No la borra el sistema como la carpeta de caché.
- **Política "caché primero"** (`CachePolicy.forceCache`): si el tile está en disco se muestra sin
  tocar la red (instantáneo, sin datos); si no, se baja y se guarda. Si falla la red y hay copia,
  se usa la copia.
- **Antigüedad:** un tile de más de **30 días** se borra y se vuelve a bajar la próxima vez que se
  vea con señal (es la "frescura" del mapa; la política de OSM pide cachear ≥ 7 días).
- **Tamaño:** tope **150 MB** (~7–10 mil tiles); al pasarlo se borran los más viejos hasta
  **120 MB**. La limpieza corre en un isolate, solo mira fecha/tamaño (no lee los tiles), al abrir
  la caché, tras cada precarga y cada 300 tiles nuevos.
- **Un solo cliente HTTP** (Dio) para todos los mapas y la precarga; User-Agent
  `flutter_map (bo.com.dismac.logistics_app)` como exige la tile usage policy de OSM.
- La memoria no cambia: `OsmTileLayer` sigue sin retina, `keepBuffer` 1 / `panBuffer` 0.
- **Sin carpeta** (web, error de disco) o en `flutter test` (variable `FLUTTER_TEST`): la caché
  queda deshabilitada y los tiles van a la red con el `NetworkTileProvider` de siempre.

### Precarga de la ruta del día

```dart
Future<void> prefetchRouteTiles(List<LatLng> points, {int minZoom = 13, int maxZoom = 16})
void cancelRouteTilePrefetch()
```

- Se llama sin esperar al abrir "Entrega en curso" con las posiciones de las paradas:
  `unawaited(prefetchRouteTiles(puntos))`. Nunca lanza.
- Tiles del rectángulo de las paradas con margen (15 % del lado, mínimo ~500 m), de zoom 13 a 16
  (acotado al zoom nativo 18). Los zooms bajos van completos primero; si un zoom no entra en el
  tope se toman solo los tiles de cada parada y sus vecinos.
- **Tope 600 tiles** (≈ 9 MB en el peor caso), **2 descargas a la vez** (lo que pide OSM). Los que
  ya están en disco no se piden.
- **Con Wi‑Fi o con datos** (decisión): el tope la hace barata y el chofer suele salir del depósito
  sin Wi‑Fi, justo antes de entrar a zonas sin señal.
- Se corta sola tras 5 errores de red seguidos (sin señal) o ante un 429 del servidor. Una nueva
  llamada cancela la anterior; `cancelRouteTilePrefetch()` la corta (lo bajado queda guardado).
- Con el tile público de OSM está prohibida la descarga masiva: el tope bajo y la precarga
  limitada a la ruta del día la mantienen como uso normal. En producción se usa el servidor
  self-host (`MAP_TILES_URL`, ADR 013).
