---
name: wsl-run-toolchain
description: "WSL ya tiene toolchain Android completo + puente al emulador de Windows; la app SÍ se compila y corre desde WSL (deja obsoleto \"no hay Android SDK en WSL\")."
metadata:
  node_type: memory
  type: project
  originSessionId: b09fb122-a063-448a-9f98-c86b13899a10
  modified: 2026-10-15T21:56:42.008Z
---

El 2026-10-14 se montó en WSL todo lo necesario para **compilar y correr la app Android desde WSL** (antes CLAUDE.md y el skill decían que no se podía y que el APK solo salía de Windows/CI). Estado persistente de la máquina, no está en el repo:

- **JDK 17** (Temurin) en `~/jdk`.
- **Android SDK** en `~/Android/Sdk` (platform-tools con adb Linux, `platforms;android-36`, `build-tools;36.0.0`, NDK r28c). Flutter apunta ahí vía `flutter config --android-sdk ~/Android/Sdk --jdk-dir ~/jdk`.
- `~/.bashrc` exporta `ANDROID_HOME`, `JAVA_HOME` y el PATH del toolchain.
- `flutter doctor` → Android toolchain ✓. `flutter build apk --debug` compila (APK ~192 MB).

**Correr en el emulador de Windows desde WSL** (red `mirrored`, localhost compartido): arrancar el AVD con `emulator.exe` de Windows (p.ej. `Medium_Phone_API_36.1`), tener el adb server en WSL (`adb start-server`), y **copiar las llaves adb de Windows** (`/mnt/c/Users/ehhuallata/.android/adbkey{,.pub}` → `~/.android/`) para que el emulador quede `device` y no `unauthorized`. Luego `flutter run -d emulator-5554`.

**Teléfono físico por USB desde WSL** (2026-10-15, FUNCIONANDO con OnePlus 15 CPH2749, Android 16): WSL no ve USB directamente. La solución correcta es **usbipd-win** (pasar el USB nativo a WSL), NO el puente por `ADB_SERVER_SOCKET`. Ese puente (adb de WSL ↔ adb de Windows) se intentó primero y **ES UNA TRAMPA**: con red `mirrored` el puerto 5037 es compartido, y el adb de WSL (que relanza la extensión Flutter) lo acapara → **ningún adb de Windows puede leer dispositivos, ni Android Studio**. Ya quitado de `~/.bashrc` y `.vscode/settings.json`.

Flujo usbipd que funciona:
1. `winget install dorssel.usbipd-win` (hecho; usbipd en `C:\Program Files\usbipd-win\usbipd.exe`).
2. Teléfono en **Transferencia de archivos (MTP) + Depuración USB** → enumera como `22d9:2765` (OnePlus/OPPO, "ADB Interface").
3. `usbipd bind --busid 1-1` (**necesita admin**; se dispara con `Start-Process -Verb RunAs`). bind es persistente.
4. Matar el adb.exe de Windows (si no, "Device busy"), luego `usbipd attach --wsl --busid 1-1` (sin admin). Aparece en `lsusb`.
5. **udev**: `sudo scripts/setup-udev-android.sh` (regla para vendor 22d9 etc.). OJO: udev NO acepta comentarios al final de la línea de regla (invalida la línea). Tras instalar, re-attach o `udevadm trigger` para que aplique al dispositivo ya conectado.
6. `adb devices` → `unauthorized` → aceptar en el teléfono "Permitir siempre" → `device`. `flutter run -d <serial>`.

Lanzador `scripts/run-usb.sh [env]` hace attach + espera device + flutter run. Verificador: `scripts/android-doctor.sh`. Guía: `docs/run-usb.md`. Nota: `config/dev.json` usa `10.0.2.2` (alias de emulador); para teléfono físico contra el backend de la PC poner `API_BASE_URL` = IP LAN de la PC.

**VS Code en WSL** debe usar el Flutter de WSL, no `C:\flutter` (ese tiene CRLF y falla con `'bash\r': No such file or directory`, exited 127, consola se cierra al segundo). Fijado en `.vscode/settings.json` con `dart.flutterSdkPath=/home/ehhuallata/sdk/flutter`; requiere **Reload Window** para tomar efecto.

Cuidado con la memoria: ver [[wsl-gradle-memory-hang]]. SDK stable en `~/sdk/flutter` (no `/dismac/flutter`, que es pre-release de root).
