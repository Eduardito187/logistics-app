---
name: run-environments-config
description: "3 entornos (dev/staging/production) con su endpoint vía --dart-define-from-file config/*.json, enganchados a los botones de play de VS Code y Android Studio."
metadata:
  node_type: memory
  type: project
  originSessionId: b09fb122-a063-448a-9f98-c86b13899a10
  modified: 2026-11-11T16:46:27.933Z
---

El 2026-10-14 se dejaron los entornos para correr con el botón de play:

- `config/dev.json`, `config/staging.json`, `config/production.json` — cada uno con `ENV`, `API_BASE_URL`, `LABEL_PUBLIC_KEYS` (y pueden sumar `MAP_TILES_URL`, `PUSH_ENDPOINT`). Se inyectan con un solo arg: `--dart-define-from-file=config/<env>.json`. Los lee `lib/core/config/app_config.dart`.
- `.vscode/launch.json` → 3 configs (dev debug / staging profile / production release).
- `.run/*.run.xml` → 3 run configurations de Android Studio/IntelliJ (versionadas).

**STAGING real (nov 2026):** `http://137.131.245.152:8110/api/v1` (servidor OCI, ver
[[staging-server-access]]). Es **http en claro** → como staging corre en modo **profile**, hubo que
whitelistear esa IP en `android/app/src/{profile,debug}/res/xml/network_security_config.xml` (el
`base-config` sigue bloqueando cleartext; solo esa IP + 10.0.2.2/localhost pasan). **Release NO sirve para
staging** (bloquea todo cleartext). `LABEL_PUBLIC_KEYS` de staging sigue **vacía** → el QR Ed25519 no valida
hasta que el backend pase la clave pública de staging (el Code128 online sí anda). Production sigue
tentativa (`logistics.dismac.com.bo`).

dev apunta a `http://localhost:8110/api/v1` (antes `10.0.2.2`; por `adb reverse`). Ver [[wsl-run-toolchain]],
[[device-run-usb-wsl]].
