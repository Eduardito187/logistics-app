---
name: perf-responsive-phase
description: "Fase de optimización 2026-10-16 (1 GB RAM + teléfonos chicos a tablets): base común, reglas y trampas de layout"
metadata:
  node_type: memory
  type: project
  originSessionId: 22a12647-3b3a-43c2-a3c3-8f46fc627148
  modified: 2026-10-16T17:06:58.955Z
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
- Grillas con `childAspectRatio` fijo desbordan con letra 1.3x: usar filas sin alto fijo (`SliverCardRows` en picking/supervisor, `SliverCardGrid` en store, `AdaptiveCardList` en driver — duplicados por feature; candidato a mover a `lib/core/layout`).
- Offline invisible también en pastillas: encolado = "Registrado"/"Enviado".

**Why:** pedido explícito del dueño; terreno con equipos baratos y tablets en andén/supervisión.
**How to apply:** respetar la base y probar cada pantalla con `testOnScreens`. Pendiente: probar el APK release (R8) en un dispositivo real (push, impresión BT/USB, GPS en segundo plano).
