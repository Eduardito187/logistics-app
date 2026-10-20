---
name: test-pass-detected-flaws
description: "Falencias halladas escribiendo la batería de tests (oct-2025) y YA CORREGIDAS (#1-#10)"
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-16T05:06:46.442Z
---

Al escribir la batería exhaustiva de tests (~190 archivos, ~1000 casos, agentes en paralelo, SIN ejecutar) se detectaron falencias de producción. **Todas (#1–#10) ya fueron corregidas** y `flutter analyze` quedó limpio. Resumen de los fixes (por si reaparece un síntoma):

**Bugs reales (corregidos):**
1. `core/auth/session_notifier.dart`: bandera `_closing` → un solo cierre aunque lleguen N 401 concurrentes (antes revocaba/avisaba varias veces porque `await appLogout()` corría antes de `state=null`).
2. `core/push/push_status.dart` y `core/location/truck_tracking_state.dart`: `copyWith` con centinela `_unset` → ahora SÍ puede volver campos a `null` (antes `x ?? this.x` dejaba el valor viejo; el error rojo de push sobrevivía al registro ok).
3. `core/offline/offline_queue.dart` drain: atrapa `StateError` y aísla la fila (markFailed) en vez de romper todo el drenado ante un `kind` desconocido.
4. Mismo archivo submit: 429/5xx/conexión → `SubmitOutcome.queued` (transitorio, reintenta) en vez de `failed`; y valida el `kind` ANTES de encolar (sin fila "envenenada"). Helper `_isTransient`.
5. `core/offline/app_database.dart` markFailed: incrementa `attempts` (SQL `attempts = attempts + 1` vía customUpdate) → base para backoff/tope.
6. `driver/.../fuel_screen.dart` y `odometer_screen.dart`: la llamada al API pasó a los use cases `recordRefuelProvider`/`recordOdometerProvider` (data→domain), ya no `ref.read(logisticsApiProvider)` en presentation (regla 5 de [[clean-architecture]]). `RecordRefuel.call` ahora devuelve `AcceptedEnvelope` (202).
7. `settings/.../devices_screen.dart`: revocar el dispositivo ACTUAL llama `signOut()` de inmediato (antes dependía del próximo 401, aunque el diálogo prometía cerrar sesión).
8. `supervisor/.../supervisor_labels.dart`: helper único `planFinalEta(stops)` (ETA más tardía) usado por `plan_card.dart` y `plan_detail_body.dart` → una sola "ETA final" por plan.
9. `store/.../unit_scan.dart`: `UnitScan.result` (VerificationResult) + `unitScanErrorMessage()` → tienda distingue "firma inválida" de "clave desconocida" (igual que carrier); lo usan reception_detail y pickup_pod.
10. `core/labels/label_scan_result.dart`: getter `backendDisagrees` → expone cuando el backend contradice al escaneo offline (la decisión sigue siendo offline vía `isValid`).

Ver también [[test-battery-and-infra]].
