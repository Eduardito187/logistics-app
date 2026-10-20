---
name: windows-native-toolchain
description: "Proyecto migrado de WSL a Windows nativo (2026-10-16); Flutter 3.47.6 en C:\\sdk\\flutter, no C:\\flutter (3.32, de dismac-app)"
metadata:
  node_type: memory
  type: project
  originSessionId: 22a12647-3b3a-43c2-a3c3-8f46fc627148
  modified: 2026-10-16T05:23:58.247Z
---

El 2026-10-16 el proyecto se movió de WSL a `C:\Users\ehhuallata\Documents\APP\logistics-app` (Windows nativo). Lo de [[wsl-run-toolchain]] (usbipd, puente adb, `~/sdk/flutter`) ya NO aplica acá.

- **Flutter 3.47.6** (Dart 3.13.5, exigido por `pubspec.yaml` `sdk: ^3.13.5`) clonado en `C:\sdk\flutter`. `C:\flutter` es 3.32.0 (Dart 3.8) y NO sirve para esta app; se dejó intacto porque `dismac-app` (hermano en `Documents\APP`) lo usa.
- El `flutter` del PATH es el viejo → invocar `C:\sdk\flutter\bin\flutter.bat` (o desde Bash `/c/sdk/flutter/bin/flutter.bat`).
- `.vscode/settings.json` → `C:\sdk\flutter`; `.vscode/tasks.json` usa el adb de Windows; `android/local.properties` (ignorado por git) → `flutter.sdk=C:\sdk\flutter`, `sdk.dir=%LOCALAPPDATA%\Android\Sdk`.
- Android SDK 36.1 en `C:\Users\ehhuallata\AppData\Local\Android\Sdk`; JDK Temurin 21 en `C:\Users\ehhuallata\jdk21`. `flutter doctor` avisaba licencias Android sin aceptar (`flutter doctor --android-licenses`, lo acepta el usuario).
- `android/gradle.properties` conserva los topes de WSL (heap 2G, sin daemon, sin build cache) — inofensivos en Windows, ver [[wsl-gradle-memory-hang]].

**Why:** el usuario migró de WSL y pidió dejarlo listo para ejecutar.
**How to apply:** usar siempre `C:\sdk\flutter`; no actualizar `C:\flutter` sin preguntar (rompería/alteraría dismac-app).

**Build Android (verificada 2026-10-16):** `flutter build apk --debug --dart-define-from-file=config/dev.json` compila. Requirió vendorizar `usb_serial` 0.5.2 (última en pub.dev; usa `jcenter()` + AGP 4.1 → falla con Gradle 9.3.1 / AGP 9.1) en `third_party/usb_serial/` con `android/build.gradle` reescrito, usado vía `dependency_overrides` en pubspec y excluido del analyzer. Si usb_serial publica versión compatible, quitar el override y la carpeta.
