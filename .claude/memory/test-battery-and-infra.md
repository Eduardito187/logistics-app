---
name: test-battery-and-infra
description: Batería de tests (1726 + 6 e2e al 2026-10-16): cómo correr en Windows, seams/fakes compartidos y trampas de widget tests
metadata:
  type: project
---

Estado 2026-10-16 (cierre del roadmap): **1726/1726 verde**, `flutter analyze` limpio, **e2e 6/6** en host y en el emulador Android (`integration_test/`). Ver [[roadmap-19-cierre]].

**Correr (Windows, Flutter 3.32):** `C:\flutter\bin\flutter.bat test` (o `-j 2` si la PC está cargada); e2e en host `flutter test integration_test -d flutter-tester` (sin `-d` Windows dice "No supported devices"); `make e2e DEVICE=<id>`. Reporter útil: `--reporter json` + script que agrupe fallas por mensaje.

**Patrón:** fakes a mano + `ProviderScope`/`ProviderContainer(overrides:)`; sin Dio/GPS/HW real. Vector Ed25519 real en `test/fixtures/label_test_vector.json`.

**Seams y helpers compartidos (`test/support/`):** `fake_code_scanner.dart` (`codeScannerProvider`), `fake_photo_picker.dart` (`photoPickerProvider`), `screen_sizes.dart` (`testOnScreens` 4 tamaños + `withTextScale(1.3)`), `button_finders.dart` (`findButtonWithText<T>`/`findButton<T>`: en Flutter 3.32 los `.icon` son subclases privadas). Arneses por feature en `test/features/<f>/support/` (driver: `pumpScoped(tall:)`, `pumpPushed`, `gateBase` que ya overridea ubicación/rastreo/precarga de tiles). Plugins vía PlatformInterface (`FlutterForegroundTaskPlatform`, `UrlLauncherPlatform`, `FirebaseMessaging` falso inyectado). e2e: backend falso a nivel transporte Dio + cola offline real en Drift en memoria (`integration_test/support/`).

**Infra:** `test/flutter_test_config.dart` redirige `libsqlite3.so` en Linux (no-op en Windows; NO borrarlo).

**Trampas frecuentes:** ListView perezoso en 800x600 (usar `tall: true`/`testOnScreens`); `pumpAndSettle` con spinner infinito; `FlutterSecureStorage.setMockInitialValues({})` para logout; `initializeDateFormatting('es')` en setUpAll; `defaultTargetPlatform` es Android en tests (`debugDefaultTargetPlatformOverride`); "override a provider twice" → overridear uno más específico; ruido de `ClientException` de tiles OSM no falla tests. Reparar tests = tocar solo `test/` salvo bug real de `lib/` (ver [[test-pass-detected-flaws]]).
