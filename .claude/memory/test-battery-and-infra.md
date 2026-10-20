---
name: test-battery-and-infra
description: Batería de tests y cómo correrlos; fix de libsqlite3 en test; estado 1461/1461 verde
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-20T00:00:00.000Z
---

Existe una batería de tests exhaustiva escrita en paralelo (~190 archivos, ~1000 casos iniciales) que cubre core y los 5 roles de campo. Patrón: fakes a mano + `ProviderScope`/`ProviderContainer(overrides:)`, sin Dio/GPS/HW real; vector Ed25519 real en `test/fixtures/label_test_vector.json`.

**Infra de test clave — `test/flutter_test_config.dart`:** en WSL/Linux falta el symlink `libsqlite3.so` (solo está `libsqlite3.so.0`), así que todo test Drift (`NativeDatabase.memory()`) reventaba con "Failed to load dynamic library 'libsqlite3.so'". Ese config (lo ejecuta el framework antes de todos los tests) redirige la carga a `libsqlite3.so.0`. NO borrarlo. En Windows/CI el host suele traer la librería; el config es no-op si `libsqlite3.so` abre.

**Correr:** `flutter test` (en Windows nativo) o `export PATH="$HOME/sdk/flutter/bin:$PATH"; flutter test` (WSL). Reporter útil: `flutter test --reporter failures-only`.

**Historia (16-oct):** tras corregir #1–#10, quedaban ~50 tests fallando por BUGS DE AUTORÍA de los tests (se escribieron a ciegas, sin ejecutar), no de producción (`flutter analyze` limpio). Se lanzaron 3 agentes de reparación (driver; store+carrier; core/settings/picking/supervisor/notifications). Causa compartida del grupo driver: "Tried to modify a provider while the widget tree was building" (bug en el harness `test/features/driver/support/driver_test_support.dart`). Reparar tests = SOLO tocar archivos bajo `test/`, nunca `lib/`. Ver [[test-pass-detected-flaws]].

**1080/1080 (16-oct):** se arreglaron 15 más. En `lib/` (bugs reales): `showErrorSnack` ignoraba mensajes String (mostraba "Ocurrió un error." en validaciones de combustible/odómetro); `LabelPrinter` no atrapaba `UnsupportedError` de flutter_blue_plus; `PushEndpointNotifier._load` diferido pisaba un save/clear posterior; `VehicleSheet` desbordaba (ahora SingleChildScrollView). En `test/`: ListView perezoso en 800x600 → superficie alta (`tall: true` / `tester.view.physicalSize`); `pumpAndSettle` con spinner infinito; finder de IgnorePointer sin acotar; 500 vs 422 en ApiException.message; widget_test necesita `FlutterSecureStorage.setMockInitialValues({})` (sin mock el canal responde fuera del reloj falso y `signOut` queda trabado por `_closing`).

**1180/1180, 0 skip (16-oct tarde):** seams nuevos para tests: `codeScannerProvider` (lib/core/scanning/code_scanner.dart; `scanCode` delega si está overrideado) + helper `test/support/fake_code_scanner.dart` → flujos escaneo→submit cubiertos (chofer POD/fallida/scan_units, tienda recepción/retiro, transportista pickup/deliver, picking). Foreground service, PushService y rama Android de map_launcher se testean vía sus PlatformInterface (`FlutterForegroundTaskPlatform`, `UrlLauncherPlatform`) y `debugDefaultTargetPlatformOverride` (map_launcher usa `defaultTargetPlatform`, no dart:io). OJO: en flutter_test `defaultTargetPlatform` es Android por defecto. Seam de fotos hecho (`photoPickerProvider`) y avisos que tapaban el botón resueltos (`bottomClearance`).

**Estado final 2026-10-16: 1461/1461 VERDE.**
