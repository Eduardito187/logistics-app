# Motivos de "no se pudo entregar" configurables por el administrador

**Fecha:** 2026-11-17 · **Pide:** app (logistics-app) · **Para:** backend (logistics-e8)
**Prioridad:** 🔴 Alta · pedido directo del dueño

## Qué quiere el dueño

Que el **admin** maneje el catálogo de motivos de entrega fallida desde la app: **crear**, **mostrar
/ ocultar** (activar/desactivar) y, por cada motivo, decidir si al elegirlo hay que **pedir foto** y/o
**pedir un texto/observación**. Hoy los motivos son un enum fijo del backend (`FailureReason`:
`CUSTOMER_ABSENT`, `WRONG_ADDRESS`, `REJECTED`, `DAMAGED`, `OTHER`) y no se pueden configurar. No existe
nada así — se crea de cero.

## Modelo propuesto (catálogo `failure_reasons`)

Cada motivo:

| Campo | Tipo | Nota |
| --- | --- | --- |
| `code` | string | Identificador estable. Viaja como `reason` en el registro de fallida. **No se muestra** (el dueño no quiere códigos a la vista). Los 5 de siempre conservan su code (`CUSTOMER_ABSENT`…). |
| `label` | string | Texto que ve el chofer (español). |
| `active` | bool | Si se muestra/habilita al chofer. Desactivado = no aparece, se conserva para historial y para reactivar. |
| `requires_photo` | bool | Al elegirlo, la foto es obligatoria. |
| `requires_note` | bool | Al elegirlo, hay que escribir un texto. |
| `note_label` | string? | Etiqueta del campo de texto (p. ej. "¿Qué pasó?"). |
| `sort_order` | int | Orden de aparición (menor primero). |

**Semilla:** crear los 5 actuales como filas `active: true`, `requires_photo: false`,
`requires_note: false`, con su `code` de hoy, para no romper nada.

## Endpoints pedidos

### Lectura del chofer
```
GET /app/config/failure-reasons
→ 200 { "data": [ { code, label, active, requires_photo, requires_note, note_label, sort_order }, ... ] }
```
Puede devolver solo los `active` (o todos; la app filtra por `active` igual). Ordenado por `sort_order`.

### Administración (admin; acotado por rol/ciudad como el resto de `/app/admin/*`)
```
GET    /app/admin/failure-reasons            → 200 { "data": [ ...todos... ] }
POST   /app/admin/failure-reasons            body: { code?, label, active, requires_photo, requires_note, note_label?, sort_order }
                                              → 201 el motivo creado. Si no mandamos `code`, generalo del label (o devolvé el que asignes).
PUT    /app/admin/failure-reasons/{code}     body: { label, active, requires_photo, requires_note, note_label?, sort_order }
                                              → 200. Cubre activar/ocultar y cambiar exigencias.
DELETE /app/admin/failure-reasons/{code}     → baja LÓGICA (active=false), NO borrado físico.
```
Si un `code` ya existe en POST → 409. Errores en `application/problem+json` como el resto.

> **Decisión del backend (`logistics-e8`, 2026-11-17):** DELETE = **desactivar** (soft, `active=false`),
> no borrado físico, porque las entregas fallidas históricas guardan el `code` del motivo como string y
> borrarlo las dejaría huérfanas. Reactivar = PUT con `active=true`. La app lo refleja: **no** hay botón
> "Eliminar"; ocultar un motivo es el switch "Mostrar al chofer" (= PUT `active=false`). Si algún día se
> quiere borrado duro, el backend lo hará solo-si-no-usado (409 si referenciado).

### Registro de la fallida (cambio en `POST /app/deliveries/failed`)

Hoy `FailedDeliveryRequest.reason` es el **enum**. Para soportar motivos que crea el admin:

1. **`reason` pasa a ser string libre** validado contra el catálogo activo (no un enum cerrado). Los 5
   de siempre siguen siendo válidos (mismo code). Un `reason` que no está en el catálogo activo → 422.
2. **Nuevo campo opcional `note` (string)** con el texto que escribió el chofer.
3. Validación server-side de las exigencias (acordado con `logistics-e8`, 2026-11-17):
   - `requires_note`: **duro**. La `note` viaja completa en el body → 422 si el motivo la exige y falta.
   - `requires_photo`: **NO** bloquea por el archivo (la foto sube async por la cola `/deliveries/photos`,
     offline-first). Se da por cumplida si el body trae **`has_photo: true`** (bool opcional) o un
     `photo_path`. Solo 422 si el motivo exige foto y no llega ninguna de las dos señales. La app manda
     `has_photo: true` cuando el chofer sacó la foto (que se encola aparte); el registro de la fallida no
     espera a que la foto suba.

La app manda, por Dio directo (offline-first, Idempotency-Key en header y en el body):
```json
{ "shipment_id":"…", "unit_id":"…", "lat":-17.7, "lng":-63.1,
  "occurred_at":"2026-11-17T18:00:00.000Z", "reason":"<code>",
  "note":"opcional", "has_photo":true, "idempotency_key":"…" }
```
(`has_photo` solo cuando hubo foto; `note` solo cuando el chofer escribió algo.)

## Qué ya hizo la app (lista, no bloquea; funciona antes del deploy)

- **Catálogo** `FailureReasonOption` + `FailureReasonsRepository` (Dio directo a las rutas de arriba).
  Si el backend aún no las tiene (404/405) o no hay red, **cae a los 5 de fábrica** → el chofer nunca
  queda sin motivos (offline-first) y el admin puede empezar a configurarlos.
- **Pantalla del chofer** (`FailedDeliveryScreen`): los motivos salen del catálogo; si el elegido pide
  **texto**, aparece un campo obligatorio; si pide **foto**, la foto pasa a obligatoria y el botón se
  bloquea hasta cumplir. El registro manda `reason` = code + `note`.
- **Pantalla del admin** (`/admin/failure-reasons`, "Motivos de no entrega"): lista, switch de
  activar/ocultar, crear, editar (label, foto, texto, etiqueta del texto) y borrar.
- **Transporte offline** (`recordFailedDelivery`): ahora va por **Dio directo** a `/app/deliveries/failed`
  con `reason` string + `note` (ya no por el DTO del enum), con la misma idempotencia de la cola.

## Qué necesito del backend (resumen accionable)

1. Catálogo `failure_reasons` + los 4 endpoints (`GET app/config`, `GET/POST/PUT/DELETE app/admin`).
2. Semilla con los 5 motivos actuales.
3. En `POST /app/deliveries/failed`: `reason` string libre validado contra el catálogo + `note` opcional
   (+ validar `requires_photo`/`requires_note` si querés).
4. Tras el deploy, avisá para **regenerar el cliente** y pasar estas llamadas del Dio directo al cliente
   generado (regla #5 del proyecto).

Ver [[app-api-coverage-state]], [[unified-error-contract]], [[owner-decisions-are-final]].
