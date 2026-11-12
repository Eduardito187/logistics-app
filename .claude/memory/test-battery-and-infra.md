---
name: test-battery-and-infra
description: Batería de tests y cómo correrlos; fix de libsqlite3 (test Y e2e); seams de escáner puntual+continuo+resolver; estado 2026 unit + 6/6 e2e
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-12T12:46:37.984Z
---

Existe una batería de tests exhaustiva escrita en paralelo (~190 archivos, ~1000 casos iniciales) que cubre core y los 5 roles de campo. Patrón: fakes a mano + `ProviderScope`/`ProviderContainer(overrides:)`, sin Dio/GPS/HW real; vector Ed25519 real en `test/fixtures/label_test_vector.json`.

**Infra de test clave — `test/flutter_test_config.dart`:** en WSL/Linux falta el symlink `libsqlite3.so` (solo está `libsqlite3.so.0`), así que todo test Drift (`NativeDatabase.memory()`) reventaba con "Failed to load dynamic library 'libsqlite3.so'". Ese config (lo ejecuta el framework antes de todos los tests) redirige la carga a `libsqlite3.so.0`. NO borrarlo. En Windows/CI el host suele traer la librería; el config es no-op si `libsqlite3.so` abre.

**Correr:** `flutter test` (en Windows nativo) o `export PATH="$HOME/sdk/flutter/bin:$PATH"; flutter test` (WSL). Reporter útil: `flutter test --reporter failures-only`.

**Historia (16-oct):** tras corregir #1–#10, quedaban ~50 tests fallando por BUGS DE AUTORÍA de los tests (se escribieron a ciegas, sin ejecutar), no de producción (`flutter analyze` limpio). Se lanzaron 3 agentes de reparación (driver; store+carrier; core/settings/picking/supervisor/notifications). Causa compartida del grupo driver: "Tried to modify a provider while the widget tree was building" (bug en el harness `test/features/driver/support/driver_test_support.dart`). Reparar tests = SOLO tocar archivos bajo `test/`, nunca `lib/`. Ver [[test-pass-detected-flaws]].

**1080/1080 (16-oct):** se arreglaron 15 más. En `lib/` (bugs reales): `showErrorSnack` ignoraba mensajes String (mostraba "Ocurrió un error." en validaciones de combustible/odómetro); `LabelPrinter` no atrapaba `UnsupportedError` de flutter_blue_plus; `PushEndpointNotifier._load` diferido pisaba un save/clear posterior; `VehicleSheet` desbordaba (ahora SingleChildScrollView). En `test/`: ListView perezoso en 800x600 → superficie alta (`tall: true` / `tester.view.physicalSize`); `pumpAndSettle` con spinner infinito; finder de IgnorePointer sin acotar; 500 vs 422 en ApiException.message; widget_test necesita `FlutterSecureStorage.setMockInitialValues({})` (sin mock el canal responde fuera del reloj falso y `signOut` queda trabado por `_closing`).

**1180/1180, 0 skip (16-oct tarde):** seams nuevos para tests: `codeScannerProvider` (lib/core/scanning/code_scanner.dart; `scanCode` delega si está overrideado) + helper `test/support/fake_code_scanner.dart` → flujos escaneo→submit cubiertos (chofer POD/fallida/scan_units, tienda recepción/retiro, transportista pickup/deliver, picking). Foreground service, PushService y rama Android de map_launcher se testean vía sus PlatformInterface (`FlutterForegroundTaskPlatform`, `UrlLauncherPlatform`) y `debugDefaultTargetPlatformOverride` (map_launcher usa `defaultTargetPlatform`, no dart:io). OJO: en flutter_test `defaultTargetPlatform` es Android por defecto. Seam de fotos hecho (`photoPickerProvider`) y avisos que tapaban el botón resueltos (`bottomClearance`).

**Estado final 2026-10-16: 1461/1461 VERDE.**

---

**Infra e2e — `integration_test/` (nov 2026, corrido en WSL por primera vez).** Correr: `~/sdk/flutter/bin/flutter test integration_test -d flutter-tester`. La salida usa `\r` (una sola línea con progreso); para el tally: `tr '\r' '\n' < log | grep -E 'All tests passed|Some tests failed'`. El estado anterior "e2e 6/6" se había verificado SOLO en Windows; en WSL fallaba por los puntos de abajo.

- **`libsqlite3.so` también revienta en e2e.** `flutter_test_config.dart` NO se hereda entre carpetas de test: el de `test/` no cubre `integration_test/`. Los flujos e2e usan `AppDatabase(NativeDatabase.memory())` + cola offline real, así que sin un config propio fallan igual que los unit. Creado `integration_test/flutter_test_config.dart` (copia exacta del de `test/`: redirige a `libsqlite3.so.0` en Linux, no-op en Windows). NO borrarlo.
- **Seam del escáner CONTINUO en e2e.** El e2e solo overrideaba `codeScannerProvider` (escaneo puntual, `scanCode`). Las pantallas que escanean en ráfaga usan `scanContinuous` → `continuousScannerProvider`; sin override abren el `MobileScanner` REAL y tiran `MissingPluginException(... mobile_scanner ...)`. Fix: `FakeCodeScanner` (test/support/fake_code_scanner.dart) ahora tiene `callContinuous` (comparte la MISMA cola `_codes` que `call`, consume UN código por apertura de cámara, registra `requestedTitles`/`requestedFormats`) y `e2e_app.dart` cablea `continuousScannerProvider.overrideWithValue(h.scanner.callContinuous)`. Pantallas con `scanContinuous` hoy: picking (verificar global), recepción tienda, retiro tienda.
- **El feedback del escáner continuo (`ScanFeedback`, ej. "Etiqueta inválida: editada o falsa") vive SOLO en el overlay del escáner real**, que el fake no dibuja. Verificarlo por `h.scanner.continuousMessages` (lista de textos que devolvió cada `onCode`), NO por `find.text(...)` en pantalla.
- **Listas perezosas en e2e:** en la ventana flutter-tester muchas listas construyen solo la primera fila. No contar tiles con `findsNWidgets(n)` ni esperar "N preparados" contando tiles. Usar `scrollUntilVisible(finder, delta, scrollable: find.byType(Scrollable).last)` para construir el objetivo (delta negativo = scrollear hacia arriba), o verificar por un widget SIEMPRE construido (p. ej. el `ProgressCard`/botón global de arriba) o por el estado del `fake_backend`.
- **Entrega chofer v2 AUTO-AVANZA tras el POD:** `_register` settlea el stop local (`locallySettledStopsProvider`) y `currentStopOf` salta a la siguiente parada → NO hay botón intermedio "Siguiente entrega". El e2e espera aterrizar directo en "Parada N+1 de M".

**Estado 2026-11-11: `flutter analyze` limpio · `flutter test` 2026/2026 · `flutter test integration_test` 6/6.**

**Estado 2026-11-12: `flutter analyze` limpio · `dart format lib test` sin cambios · `flutter test` 2856/2856 VERDE** (subió desde 2770 con 4 agentes en paralelo: chofer "Mi día" por estado efectivo + rangos de fecha; tienda anti-doble-entrega (`deliveredUnitIdsProvider`); transportista rehidrata la tanda de escaneo desde la cola offline + bloquea pantallas de oficina por rol; auth manda el modelo real del equipo en `device.name` leyendo `build.prop` sin dependencias nuevas). **Trampa que dejó un agente:** sus 4 tests nuevos de `auth_repository_impl_test.dart` no pasaban `meResponse` y el fake `me()` hacía `meResponse!` (null-check) → reventaba fuera del `try/catch` de `ApiException` de `_completeSignIn`. Fix: el fake `me()` ahora lanza `ApiException(503)` cuando no hay `meResponse` (simula "/me no disponible" = degradación segura), así los tests que solo miran device/login no tienen que armar un `AppMeResponse` completo.

**Seam del resolver de etiquetas (nov 2026):** además de `codeScannerProvider`/`continuousScannerProvider`,
está `labelResolverProvider` (Code128 → `/resolve`). Tests que escanean códigos PLANOS (no-QR) necesitan
`labelResolverProvider.overrideWithValue(FakeLabelResolver(echo:true))`; si falta, el código plano va a
resolver online → red → se rechaza y el test rompe. Detalle en [[code128-label-scanning]].

**`flutter run` queda ADJUNTO para siempre (no es una tarea colgada):** una build en background con
`flutter run` nunca "termina" sola — se queda con hot-reload + logs del dispositivo. Si el dueño ve una
"tarea ejecutando hace N min", suele ser esto: `TaskStop <id>` + `pkill -9 -f 'flutter.*run -d <ip>'` (y su
`frontend_server_aot`/`dds_aot`). NO matar los `dart language-server`/`devtools`/`dart_tooling_daemon` ni el
`flutter daemon --show-web-server-device`: son de la extensión de VS Code (alimentan el análisis del IDE).

**Agentes para tests/código: VERIFICAR SIEMPRE su salida (nov 2026).** Dos agentes fallaron: uno dejó un
archivo SINTÁCTICAMENTE ROTO (llave de más + indentación mala en una función top-level) y otro se COLGÓ
20+ min sin terminar el widget ni los tests. El coordinador debe correr `getDiagnostics` sobre CADA archivo
que tocó el agente y completar lo que falte; no asumir que "cerró" = "quedó bien". Ver
[[parallel-agents-method]].
