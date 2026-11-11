---
name: run-environments-config
description: "3 entornos (dev/staging/production) con su endpoint vía --dart-define-from-file config/*.json, enganchados a los botones de play de VS Code y Android Studio."
metadata:
  node_type: memory
  type: project
  originSessionId: b09fb122-a063-448a-9f98-c86b13899a10
  modified: 2026-10-15T06:43:01.610Z
---

El 2026-10-14 se dejaron los entornos para correr con el botón de play:

- `config/dev.json`, `config/staging.json`, `config/production.json` — cada uno con `ENV`, `API_BASE_URL`, `LABEL_PUBLIC_KEYS` (y pueden sumar `MAP_TILES_URL`, `PUSH_ENDPOINT`). Se inyectan con un solo arg: `--dart-define-from-file=config/<env>.json`. Los lee `lib/core/config/app_config.dart`.
- `.vscode/launch.json` → 3 configs (dev debug / staging profile / production release).
- `.run/*.run.xml` → 3 run configurations de Android Studio/IntelliJ (versionadas).

**Pendiente de confirmar con el dueño** (puse valores tentativos): URL de **staging** la inventé (`logistics-staging.dismac.com.bo`); production salió de un comentario (`logistics.dismac.com.bo`). `LABEL_PUBLIC_KEYS` de staging/prod quedaron **vacías** (dev tiene la del test vector) — sin esa clave la verificación Ed25519 de etiquetas no valida. Falta que pase URLs y claves reales.

dev apunta a `http://10.0.2.2:8110/api/v1` (alias del host desde el emulador Android). Ver [[wsl-run-toolchain]].
