---
name: run-environments-config
description: Entornos dev/staging/production en config/*.json (--dart-define-from-file), claves vigentes y pendientes de valores reales
metadata:
  type: project
---

`config/dev.json`, `config/staging.json`, `config/production.json` se inyectan con `--dart-define-from-file=config/<env>.json` (botones de play: `.vscode/launch.json` y `.run/*.run.xml`; `make apk ENV=…`). Los lee `lib/core/config/app_config.dart`.

Claves vigentes (2026-10-16): `ENV`, `API_BASE_URL`, `LABEL_PUBLIC_KEYS`, `APP_UPDATE_URL`, `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_BUNDLE_ID`, `FIREBASE_IOS_API_KEY` (opcional) y opcional `MAP_TILES_URL`. (`PUSH_ENDPOINT` ya no existe.) `scripts/check-config.ps1` dice qué falta sin imprimir valores.

**Pendiente del dueño:** URLs reales de staging/production (las actuales son tentativas), `LABEL_PUBLIC_KEYS` de staging/prod (vacías → no se validan etiquetas), todas las `FIREBASE_*` (push/Crashlytics inactivos), `APP_UPDATE_URL`.

dev apunta a `http://10.0.2.2:8110/api/v1` (emulador). En un teléfono físico hay que usar la IP LAN de la PC. **Un APK release bloquea `http://`** (networkSecurityConfig): probar release contra staging/production. Ver [[windows-native-toolchain]].
