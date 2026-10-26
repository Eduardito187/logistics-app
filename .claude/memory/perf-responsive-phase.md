---
name: perf-responsive-phase
description: "Fase de optimización 2026-10-16 (1 GB RAM + teléfonos chicos a tablets): base común, reglas y trampas de layout"
metadata:
  node_type: memory
  type: project
  originSessionId: 22a12647-3b3a-43c2-a3c3-8f46fc627148
  modified: 2026-10-20T05:16:55.871Z
---

Objetivo del dueño: la app debe andar en teléfonos de **1 GB de RAM** y verse bien desde teléfonos chicos (320x568 dp) hasta tablets grandes (1280x800). Hecho el 2026-10-16 con 6 agentes en paralelo por carpeta ([[parallel-agents-method]]); 1461 tests verdes.

**Base común (usar siempre):**
- `lib/core/layout/breakpoints.dart` (`AppBreakpoints.columnsFor`, `maxContentWidth` 720, `maxFormWidth` 520) y `responsive_body.dart` (`ResponsiveBody`).
- `lib/core/media/photo_picker.dart`: `photoPickerProvider` (fotos reducidas 1600/70); previews con `Image.file(cacheWidth: 800)`. Test: `test/support/fake_photo_picker.dart`.
- Avisos: éxito/info 2 s, error 4 s; `bottomClearance: kBottomActionClearance` en pantallas con botón fijo al pie; `buildAppSnackBar`.
- `test/support/screen_sizes.dart`: `testOnScreens` (smallPhone/phone/tabletPortrait/tabletLandscape) + `withTextScale(1.3)`. Toda pantalla nueva debería tener su test de tamaños.
- Global: caché de imágenes 40 MB/80 (main.dart), letra tope 1.3x (app.dart), tema cacheado, `InkRipple`, densidad `standard`, toques ≥48 dp (botones principales 56).
- Android release: R8 + shrinkResources con `proguard-rules.pro`/`keep.xml`; `make apk ENV=...` → `--split-per-abi` (≈26–32 MB por ABI). Sin `largeHeap` (adrede). Detalle en `docs/rendimiento-y-pantallas.md`.
- Mapa: usar `const OsmTileLayer()` (nunca `buildOsmTileLayer()` en un build frecuente: crea clientes HTTP que no se cierran). Cola offline: índices, `watchQueue` sin payload (máx 200), drenado en lotes de 25 sin solaparse. GPS: 10 s / 20 m.

**Trampas:**
- El tema da a Filled/OutlinedButton `minimumSize: Size.fromHeight(56)` (ancho mínimo INFINITO, a propósito para botones a lo ancho): dentro de un `Row` sin `Expanded` rompe el layout → envolver en `Expanded` o pasar `minimumSize: Size(48, 56)`.
- `EmptyState` no scrollea; NO meterle `LayoutBuilder`/scroll interno: las pantallas lo usan en `SliverFillRemaining(hasScrollBody: false)` (pide medidas intrínsecas → rompe). El scroll se resuelve en cada pantalla.
- Grillas con `childAspectRatio` fijo desbordan con letra 1.3x: usar filas sin alto fijo → `lib/core/layout/adaptive_card_rows.dart` (`SliverAdaptiveCardRows` / `AdaptiveCardRows`), ya unificado (los duplicados por feature se borraron).
- Offline invisible también en pastillas: encolado = "Registrado"/"Enviado".

**Segunda pasada (2026-10-19, 4 agentes + coordinador; 1803 tests):** `lib/core/performance/` (`DeviceMemory` vía canal nativo `bo.com.dismac/device_memory` en MainActivity.kt/AppDelegate.swift → `MemoryBudget` 24/40/64 MB; `MemoryPressureObserver` vacía la ImageCache ante presión y, en gama baja, al pausar; `deviceMemoryProvider` para que pantallas ahorren con `isLowEnd`). Android con **Skia** (`EnableImpeller=false` en el manifest, decisión por drivers Vulkan de gama baja; iOS siempre Impeller). Trazos de ruta simplificados (Douglas-Peucker 5 m) y memoizados por ruta (`route_points.dart`, `Expando`); capas de flutter_map fijas reusadas (si se recrea el widget del Polyline, reproyecta todo); el GPS solo reconstruye mapa + tarjeta. Listas de tienda en slivers (`SliverSectionCard`). Topes de estado local (20 envíos, 500 estantes, 200 registros). Tiles: `CachedTileImageProvider` propio, 4 conexiones; `flutter_map_cache` quitado del pubspec. GPS pendiente > 7 días se descarta (solo `ingestTruckPosition`). Mapa de flota refresca cada 30 s y se pausa oculto. Notificaciones 30/página, tope 150. Todo en la tabla de `docs/rendimiento-y-pantallas.md`.
**Lección:** a un agente NO decirle "revertí lib/core/api con git checkout" — el cliente regenerado sin commitear se pierde (pasó; se regeneró con `scripts/regen_api_client.ps1`).

**Fase 3 velocidad (2026-10-20, 1923 tests):** causas reales de "a veces lenta": escaneo esperaba red (`submit` ahora ≤1,5 s, `labels/verify` sin await), GPS bloqueante hasta 6 s (`current()` ≤1,5 s + `prefetch()`), re-fetch con spinner en cada navegación (`ref.cacheFor(CacheTtl.short|long)` en `core/performance/cache_for.dart`), Riverpod reintentando 10x (`appProviderRetry` en `main.dart`), rastreo GPS reiniciado por `.asData?.value`. Escáner continuo `scanContinuous` (fakes `continuousScannerProvider`). Arranque: `TokenStore.preload()` (un `readAll`), WorkManager/push/drenado tras el primer cuadro, `UiAliveBeacon` evita que WorkManager duplique con la UI al frente. `signOut` instantáneo: el guard `_closing` cubre SOLO el cierre local (si cubre el fondo, una sesión nueva no puede cerrarse). Tabla en `docs/rendimiento-y-pantallas.md` § Velocidad percibida.
**Medir bien:** debug en emulador es 3–10x más lento → juzgar con `flutter run --release`/`--profile`. Backend dev ~200 ms/request es casi todo Xdebug con todos los modos (~150 ms); prod ~25–30 ms.

**Why:** pedido explícito del dueño; terreno con equipos baratos y tablets en andén/supervisión.
**How to apply:** respetar la base y probar cada pantalla con `testOnScreens`. Pendiente: probar el APK release (R8) en un dispositivo real (push, impresión BT/USB, GPS en segundo plano).
