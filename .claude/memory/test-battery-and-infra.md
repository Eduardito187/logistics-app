---
name: test-battery-and-infra
description: Batería de tests (WSL+Windows merge): cómo correr en Windows/WSL, seams/fakes compartidos, trampas de widget tests y fix de libsqlite3; conteo en re-verificación tras el merge
metadata:
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-20T00:00:00.000Z
---

Batería de tests exhaustiva (core + los 5 roles de campo). Estado pre-merge (cierre del roadmap, 2026-10-16): **1726/1726 verde**, `flutter analyze` limpio, **e2e 6/6** en host y emulador Android (`integration_test/`). Ver [[roadmap-19-cierre]]. (Tras el merge WSL+Windows el conteo se re-verifica.)

**Correr (Windows, Flutter 3.32):** `C:\flutter\bin\flutter.bat test` (o `-j 2` si la PC está cargada); e2e en host `flutter test integration_test -d flutter-tester` (sin `-d` Windows dice "No supported devices"); `make e2e DEVICE=<id>`. Reporter útil: `--reporter json` + script que agrupe fallas por mensaje.

**Patrón:** fakes a mano + `ProviderScope`/`ProviderContainer(overrides:)`; sin Dio/GPS/HW real. Vector Ed25519 real en `test/fixtures/label_test_vector.json`.

**Seams y helpers compartidos (`test/support/`):** `fake_code_scanner.dart` (`codeScannerProvider`), `fake_photo_picker.dart` (`photoPickerProvider`), `screen_sizes.dart` (`testOnScreens` 4 tamaños + `withTextScale(1.3)`), `button_finders.dart` (`findButtonWithText<T>`/`findButton<T>`: en Flutter 3.32 los `.icon` son subclases privadas). Arneses por feature en `test/features/<f>/support/` (driver: `pumpScoped(tall:)`, `pumpPushed`, `gateBase` que ya overridea ubicación/rastreo/precarga de tiles). Plugins vía PlatformInterface (`FlutterForegroundTaskPlatform`, `UrlLauncherPlatform`, `FirebaseMessaging` falso inyectado). e2e: backend falso a nivel transporte Dio + cola offline real en Drift en memoria (`integration_test/support/`).

**Infra:** `test/flutter_test_config.dart` redirige `libsqlite3.so` en Linux (no-op en Windows; NO borrarlo).

**Trampas frecuentes:** ListView perezoso en 800x600 (usar `tall: true`/`testOnScreens`); `pumpAndSettle` con spinner infinito; `FlutterSecureStorage.setMockInitialValues({})` para logout; `initializeDateFormatting('es')` en setUpAll; `defaultTargetPlatform` es Android en tests (`debugDefaultTargetPlatformOverride`); "override a provider twice" → overridear uno más específico; ruido de `ClientException` de tiles OSM no falla tests. Reparar tests = tocar solo `test/` salvo bug real de `lib/` (ver [[test-pass-detected-flaws]]).
