---
name: test-battery-and-infra
description: Batería de tests (~1000 casos) y cómo correrlos; fix de libsqlite3 en test; 3 agentes de reparación quedaron pendientes
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-16T05:07:01.116Z
---

Existe una batería de tests exhaustiva escrita en paralelo (~190 archivos, ~1000 casos) que cubre core y los 5 roles de campo. Patrón: fakes a mano + `ProviderScope`/`ProviderContainer(overrides:)`, sin Dio/GPS/HW real; vector Ed25519 real en `test/fixtures/label_test_vector.json`.

**Infra de test clave — `test/flutter_test_config.dart`:** en WSL/Linux falta el symlink `libsqlite3.so` (solo está `libsqlite3.so.0`), así que todo test Drift (`NativeDatabase.memory()`) reventaba con "Failed to load dynamic library 'libsqlite3.so'". Ese config (lo ejecuta el framework antes de todos los tests) redirige la carga a `libsqlite3.so.0`. NO borrarlo. En Windows/CI el host suele traer la librería; el config es no-op si `libsqlite3.so` abre.

**Correr:** `export PATH="$HOME/sdk/flutter/bin:$PATH"; cd <repo>; flutter test`. Reporter útil: `flutter test --reporter failures-only`.

**PENDIENTE (al 16-oct-2025):** tras corregir #1–#10, quedaban ~50 tests fallando por BUGS DE AUTORÍA de los tests (se escribieron a ciegas, sin ejecutar), no de producción (`flutter analyze` limpio). Se lanzaron 3 agentes de reparación (driver; store+carrier; core/settings/picking/supervisor/notifications) que SE DETUVIERON al cerrarse la sesión; su progreso quedó guardado en los transcripts. `test/core/offline/` ya está verde (ajustado a mano a los fixes). Causa compartida del grupo driver: "Tried to modify a provider while the widget tree was building" (bug en el harness `test/features/driver/support/driver_test_support.dart`). Reparar tests = SOLO tocar archivos bajo `test/`, nunca `lib/`. Ver [[test-pass-detected-flaws]].
