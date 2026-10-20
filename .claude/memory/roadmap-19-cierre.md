---
name: roadmap-19-cierre
description: Cierre de los 19 puntos del roadmap (2026-10-16) con 9 agentes en paralelo: qué quedó, decisiones y pendientes del usuario/backend
metadata:
  type: project
---

El 2026-10-16 se cerraron los 19 puntos del roadmap con 9 agentes en paralelo ([[parallel-agents-method]]). Estado final: `flutter analyze` limpio, 1726/1726 tests, e2e 6/6 (host y emulador), release firmado (≈25–31 MB por ABI). 6 commits `DIS-0000 | ...` en `feature/initial-scaffold` (sin push: el auto-mode bloqueó el push; el usuario lo hace y abre el PR a `dev` con `.claude/skills/github-pr-flow/scripts/create-pr.ps1`, textos en `%TEMP%/pr_title.txt` y `pr_body.md`).

**Decisiones:** iOS SÍ (proyecto regenerado para 3.32, iOS 15+, bundle `bo.com.dismac.logisticsApp`, protección `CompleteUntilFirstUserAuthentication` para que la cola/GPS funcionen bloqueado). Sin SQLCipher (EOL; la base solo guarda cola y fotos pendientes) → minimizar, purgar, allowBackup=false. Crashlytics como monitoreo. Sin TTS. Sin navegación giro a giro (se delega a la app de mapas). Flutter sigue 3.32; el cliente API se regenera con `scripts/regen_api_client.ps1` (usa `C:\sdk\flutter` 3.47 en copia temporal, `tool/api_gen/`). workmanager 0.9.2 con `dependency_overrides` (platform_interface 0.9.3, android 0.9.2) porque 0.9.4 no compila con workmanager_apple; sacar al poder usar 0.10.x (Flutter ≥3.38).

**Cableado en main/app:** initCrashReporting + overrides (crashReporter, CrashlyticsFailureReporter), appBuildInfo.ensureLoaded, initBackgroundSync, restore, drainOnStartup; app.dart: crashSessionBinder, VersionGate en builder, highContrast (theme/darkTheme/themeMode); router con CrashNavigationObserver.

**Pendiente del usuario:** respaldar `android/keystore/upload-keystore.jks` + `android/key.properties` fuera de la PC; cargar secrets ANDROID_* en GitHub; credenciales FIREBASE_* (+ iOS) y APNs; probar en dispositivo real con `docs/qa-dispositivo-real.md`; Mac/cuenta Apple para iOS. **Backend:** `docs/backend-requests/README.md` (destination_node_id en ingest, push 1-a-1 y topics, versión mínima, kind `signature`, foto POD obligatoria, nombrar schemas anónimos, KPIs, `POST /app/outbox-failures`).

**Why:** pedido del dueño de cerrar todo al 100% con agentes en paralelo.
**How to apply:** partir de este estado; no reabrir decisiones sin que el dueño lo pida.
