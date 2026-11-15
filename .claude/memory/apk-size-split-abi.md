---
name: apk-size-split-abi
description: "nov 2026 — el APK \"pesado\" (94.5 MB) era universal (4 ABIs); el real por ABI (arm64) pesa 32.7 MB; cómo compilar/medir/instalar liviano"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-13T14:54:39.585Z
---

**El APK se ve "pesado" (94.5 MB) sólo si es UNIVERSAL (nov 2026).** Análisis con
datos reales (desglose del APK con `unzip -l` agrupando por carpeta): el ~95% del
peso son **librerías nativas de 4 arquitecturas** metidas juntas:
`lib/x86_64` 30.6 MB + `lib/arm64-v8a` 28.5 MB + `lib/armeabi-v7a` 25.1 MB +
`lib/x86` 5.9 MB; TODO lo demás (classes.dex + assets + res) ~7 MB. Dentro de
arm64: `libapp.so` 11.6 (código Dart AOT) + `libflutter.so` 10.8 (motor) +
`libbarhopper_v3.so` 4.7 (MLKit del escáner) + `libsqlite3.so` 1.5 + assets 1.7.
**No hay grasa en el código**; el peso es puramente los 4 ABIs.

**Tamaños medidos:**
- Universal (`flutter build apk`): **94.5 MB**.
- arm64 split (`--split-per-abi` → `app-arm64-v8a-release.apk`): **32.7 MB** (−65%).
  armeabi-v7a 29.3 MB, x86_64 34.8 MB.

**TRAMPA clave:** `flutter build apk --target-platform android-arm64` **NO** da un APK
arm64 puro: baja a arm64 sólo el MOTOR (libflutter/libapp), pero las librerías de los
PLUGINS siguen trayendo las 4 ABIs → quedó en **50.5 MB**. Para un APK realmente de un
solo ABI (plugins incluidos) hay que usar **`--split-per-abi`** (splits de Gradle, que
filtran TODOS los .so por ABI). La distribución de producción (`make apk`, CI
`release-apk`) YA usa `--split-per-abi` → los choferes siempre instalaron ~33 MB; el
94.5 era sólo una instalación rápida mía del universal.

**Cómo instalar el liviano en el teléfono:**
`flutter build apk --release --split-per-abi --dart-define-from-file=config/staging.json`
→ `adb -s <dev> install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
Sin `key.properties` el release se firma con la clave de DEBUG (ver build.gradle.kts
línea ~78), así que se puede compilar `--release` para probar sin firma real.

**Para bajar aún más (opcional, no urgente):** (1) distribuir sólo arm64 si toda la
flota es 64 bits — ojo, teléfonos de 1 GB a veces son 32 bits (armeabi-v7a); (2) AAB si
migran a Managed Google Play (Play arma por equipo, ~30 MB); (3) `--obfuscate
--split-debug-info` recorta ~1-2 MB del libapp.so + protege el código; (4) MLKit "bajo
demanda" quitaría ~5.5 MB pero rompe el escaneo offline en el 1er uso (NO recomendado).

Ver [[windows-native-toolchain]], [[device-run-wireless-adb]], [[perf-responsive-phase]].
