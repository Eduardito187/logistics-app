---
name: windows-native-toolchain
description: Proyecto en Windows nativo con Flutter 3.32.0 / Dart 3.8 (C:\flutter) por pedido del usuario; versiones fijadas de deps y Gradle
metadata:
  node_type: memory
  type: project
  originSessionId: 22a12647-3b3a-43c2-a3c3-8f46fc627148
  modified: 2026-10-22T02:32:27.869Z
---

El 2026-10-16 el proyecto se clonó a `C:\Users\ehhuallata\Documents\APP\logistics-app` (Windows nativo). **El dueño trabaja en AMBOS**: Windows nativo y este WSL (`/dismac/logistics-app`). Al 2026-10-21 WSL volvió a usarse activamente para compilar y probar en teléfono físico por ADB inalámbrico (ver [[device-run-wireless-adb]]); o sea [[wsl-run-toolchain]] NO está obsoleto. La versión de Flutter (3.32.0 / Dart 3.8) y las deps fijadas de abajo valen en los dos OS.

**El usuario pidió explícitamente igualar el proyecto a SU Flutter: 3.32.0 / Dart 3.8.0 en `C:\flutter`** (el mismo que usa `dismac-app`). Se bajó el proyecto desde Flutter 3.47.6 / Dart 3.13.5. No volver a subirlo sin que lo pida.

Lo que implicó la bajada (todo verificado: analyze limpio, 1180/1180 tests, APK debug compila):
- `pubspec.yaml`: `sdk: ^3.8.0`; `flutter_riverpod ^3.3.2` (3.4.x exige Dart 3.12), `go_router ^17.0.0`, `flutter_secure_storage ^10.3.4` (11.x choca por win32 con package_info_plus 9), `package_info_plus ^9.0.1`, `retrofit_generator ^10.2.0`, `json_serializable ^6.11.2`, `json_annotation ^4.9.0`. El `retrofit_generator` no compila en Dart 3.8: el cliente se regenera con `scripts/regen_api_client.ps1` (copia temporal con Flutter 3.47), probado con resultado idéntico (ver [[api-client-generation]]).
- APIs de Flutter que no existen en 3.32: `DropdownButtonFormField(initialValue:)` → `value:`; `RadioGroup` → `groupValue`/`onChanged` en cada `RadioListTile`.
- Tests: en 3.32 `FilledButton.icon`/`OutlinedButton.icon` son subclases privadas y `find.widgetWithText/byType` (tipo exacto) no los hallan → usar `findButtonWithText<T>()` / `findButton<T>()` de `test/support/button_finders.dart`.
- Android: Gradle 8.12, AGP 8.7.3, Kotlin 2.1.0 (máximos de Flutter 3.32), `id("kotlin-android")` en app, sin flags `android.newDsl`/`builtInKotlin`, `minSdk = 24`, `compileSdk = 36` y `ndkVersion = "27.0.12077973"` fijos (3.32 trae 21/35/NDK 26; los plugins piden más). `usb_serial` sigue vendorizado en `third_party/` (inofensivo).
- **`mobile_scanner` fijado EXACTO en `7.2.0`** (no rango, no `^`). Razón doble: 7.2.1+/7.3+ suben CameraX a 1.6.1, que exige AGP 8.9.1 (incompatible con Flutter 3.32) → el APK no compila; y 7.2.0 usa en iOS Apple Vision (no MLKit) → evita el conflicto de CocoaPods `GoogleDataTransport` con firebase_messaging. Commit 9fdce63. No subirlo sin subir también Flutter/AGP.
- `dart format` de Dart 3.8 difiere del de 3.13: formatear siempre con `C:\flutter`. CI fijada a `flutter-version: 3.32.0`.
- `.vscode/settings.json` → `C:/flutter` (barras normales: con `\` simple el JSON quedaba inválido y VS Code lo ignoraba). OJO: la herramienta Bash colapsa `\\` en heredocs; escribir rutas/JSON con Write o barras `/`.
- `C:\sdk\flutter` (3.47.6) se usa SOLO para regenerar el cliente API (`scripts/regen_api_client.ps1`): NO borrarlo.
- Android SDK en `%LOCALAPPDATA%\Android\Sdk`; JDK 21 en `C:\Users\ehhuallata\jdk21`.

**Why:** el usuario quiere una sola versión de Flutter en su PC.
**How to apply:** usar `C:\flutter\bin\flutter.bat`; no usar APIs de Flutter > 3.32 ni paquetes que exijan Dart > 3.8.

**Conflicto WSL ↔ Windows (2026-10-16):** algo en WSL (casi seguro una ventana de VS Code en modo WSL/Remote con la extensión Dart, o Android Studio de WSL) corre `pub get`/sync de Gradle sobre esta misma carpeta y reescribe `.dart_tool/package_config.json`, `pubspec.lock` (con Flutter 3.47 → pide Dart ≥3.11) y `android/local.properties` con rutas `/home/ehhuallata/...`, rompiendo la build de Windows ("SDK location not found" / "Included build ...home... does not exist"). Arreglo: `C:\flutter\bin\flutter.bat pub get` + reescribir local.properties con `C:/flutter` y `C:/Users/ehhuallata/AppData/Local/Android/Sdk`. Pedir al usuario abrir el proyecto solo con VS Code de Windows (no WSL).

**Trampas del entorno de trabajo (Claude Code en esta PC):**
- La herramienta Bash colapsa `\\` dentro de heredocs (`'\n'` sale como salto real, `C:\flutter` → `C:` + form feed): escribir scripts/JSON con la herramienta Write o usar barras `/`.
- Python de Windows no tiene PyYAML: preprocesar el OpenAPI con `wsl.exe -d Ubuntu-22.04 -- python3 -I /mnt/c/...`.
- Grep sobre `\\wsl.localhost\...` desde Windows es lentísimo (timeouts): correr un `.sh` dentro de WSL.
- PowerShell 5.1 + `wsl.exe -- bash -c "..."` con comillas anidadas rompe: usar un `.sh` en el scratchpad.
- Publicar (git push) puede quedar bloqueado por el modo de permisos: dejar commits listos y darle al usuario los comandos.
