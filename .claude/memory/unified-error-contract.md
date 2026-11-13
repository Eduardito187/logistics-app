---
name: unified-error-contract
description: nov 2026 — backend unificó TODOS los errores a RFC 7807 (application/problem+json); el app lee detail ?? error.message y ramifica por code; 500 queda en español; codes de dominio en $unknown
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-13T13:05:45.075Z
---

**Contrato unificado de errores (nov 2026, backend logistics-42).** El backend
unificó TODAS las respuestas de error de la API (4xx y 5xx, todas las puertas
`/app/*`, `/channels/*`, `/integrations/*`, todos los contextos) a un solo shape
RFC 7807 `application/problem+json`:

```
{ "type":"/problems/<code>", "title":"...", "status":422,
  "code":"<code estable>", "detail":"<motivo legible>",
  "error": { "code":"<code>", "message":"<mismo motivo>" },   // redundante, idéntico
  "errors": { "campo": ["..."] } }                             // solo 422 validation_failed
```

El motivo va SIEMPRE y redundante en `detail` Y `error.message`; el código en
`code` Y `error.code`. El éxito NO cambió (`{data:...}` / 202 `{data:{accepted:true}}`).

**Qué hace el app (ya adaptado).** `lib/core/network/api_exception.dart`
(`ApiException.fromDio`) lee `detail ?? error.message` y `code ?? error.code`
(respaldo al `error` anidado). Eso cubre el shape nuevo, el viejo
`{error:{code,message}}` y el `error`/problem POR ÍTEM del **207 por lotes** (el
scan batch sigue dando 207 con un problem por ítem). TODO el pipeline de errores
pasa por `ApiException` (la cola offline usa `e.message`; no hay parseo manual en
data sources), así que con ese único fix ya no se cae al genérico "no se pudo,
intentá luego" cuando hay motivo. Tests en `api_exception_test.dart`.

**Dos decisiones del lado app (acordadas con el backend logistics-42):**
1. **500 = texto fijo en español, no `detail`.** Los 5xx (`server_error`, y
   `evidence_upload_failed` = falla de almacenamiento S3) son infra NO accionable
   por el chofer → se muestran "Error del servidor, probá de nuevo", NO el
   `detail` (que en 5xx es genérico en inglés). El backend movió el único caso
   accionable (foto POD ilegible/corrupta) a **422 code `evidence_unreadable`**
   (RENOMBRADO de `evidence_hash_failed`; NO ramificar por el viejo) con detail
   "No se pudo procesar la foto. Volvé a tomarla." → el chofer ve qué hacer.
2. **Codes de dominio: el backend YA los agregó al `openapi/v1.yaml`** (enum
   `ProblemCode` 23→36): `invalid_route`, `delivery_not_found`,
   `node_reception_not_found`, `evidence_unreadable`, `evidence_upload_failed`,
   `label_already_emitted`, `order_not_found`, `voucher_not_found`/`_expired`
   (410)/`_redeemed`/`_held`/`_holder_mismatch`/`_revoked` (409). También agregó
   el bloque `error` (code+message) al schema `Problem`. **El app NO referencia
   ninguno de esos codes todavía** (nada ramifica por ellos; solo muestra
   `detail`), así que REGENERAR el cliente es puramente ADITIVO y SIN valor
   funcional inmediato — `ApiException` parsea el Map crudo, no el modelo
   `Problem` generado. Regenerar (`scripts/regen_api_client.ps1`, ojo DataN) solo
   cuando haya una UX concreta que necesite ramificar por un code de dominio
   (p.ej. `label_already_emitted` → mensaje propio). El enum es NO exhaustivo a
   propósito → conservar SIEMPRE el fallback `$unknown`→mostrar `detail`.

Acuerdo con el backend: sigue mandando AMBOS (`detail` + `error.message`,
idénticos), no estandariza en `detail` solo (así cubre shape viejo + 207
por-ítem). Los cambios del backend están en working tree sin commitear (el dueño
corre gates y despliega). Ver [[app-api-coverage-state]], [[api-client-generation]],
[[test-pass-detected-flaws]], [[pod-scanner-vehicle-hardening]].
