# Pedido al backend: reporte de acciones offline rechazadas (`POST /app/outbox-failures`)

**De:** app interna (logistics-app) · **Para:** agente/equipo del repo `logistics` (backend)
**Fecha:** 2026-10-16 · **Relacionado:** decisión de producto "offline invisible"

## Contexto

La app es offline-first: cada escritura de terreno (escaneo de carga/descarga, POD, entrega
fallida, incidente, recepción en tienda, foto de evidencia...) se guarda primero en el teléfono
con un ULID que viaja como `Idempotency-Key` y se sube después (al volver la señal, al abrir la
app o desde una tarea de fondo cada 15 min).

Por decisión de producto el usuario de campo **no ve** el estado offline: lo encolado se informa
igual que lo enviado ("Registrado."). Consecuencia: si el backend **rechaza** una acción al
sincronizarla (4xx no transitorio: 409 por estado, 422 de validación, 403, 404...), la fila queda
`failed` en el teléfono **y nadie se entera**. Hoy esos hechos se pierden en silencio y la torre
de control ve un envío "trabado" sin explicación.

La app ya registra cada rechazo como un evento interno (`FailureReporter`) y lo enviará a
Crashlytics, pero eso es para desarrolladores. La torre de control necesita verlo en su panel.

## Pedido

### 1. Endpoint `POST /app/outbox-failures` (lote)

Autenticado con el Bearer de la puerta `/app/*` (mismo usuario + dispositivo, `X-Device-Id`).
Recibe un lote de fallas; la app lo envía al sincronizar (best-effort, con su propia cola).

```json
{
  "failures": [
    {
      "id": "01JA2B3C4D5E6F7G8H9J0KLMNP",
      "queue": "action",
      "kind": "recordLoadScan",
      "reason": "rejected",
      "status": 409,
      "problem_code": "conflict",
      "attempts": 1,
      "occurred_at": "2026-10-16T14:03:11.000Z"
    }
  ]
}
```

| Campo | Tipo | Notas |
|---|---|---|
| `id` | string (ULID) | La `Idempotency-Key` de la acción (o id local de la foto). Permite cruzar con los logs del backend. |
| `queue` | `action` \| `photo` | Cola local de origen. |
| `kind` | string | Nombre de la operación del cliente (`recordLoadScan`, `recordProofOfDelivery`, `reportVehicleIncident`...) o `pod`/`damage` para fotos. |
| `reason` | `rejected` \| `retries_exhausted` \| `invalid_payload` \| `unknown_kind` | `rejected` = 4xx del backend; `retries_exhausted` = 50 respuestas 429/5xx seguidas; los otros dos son fallas locales (sin `status`). |
| `status` | int \| null | Código HTTP recibido. |
| `problem_code` | string \| null | `code` RFC 7807 del catálogo (`ProblemCode`). |
| `attempts` | int | Intentos acumulados. |
| `occurred_at` | date-time | Momento del hecho en terreno. |

- **Idempotente por `id`**: reenviar el mismo lote no duplica (la app puede reintentar).
- Respuesta: `202 Accepted` con `AcceptedEnvelope` (o `204`). Lote máximo sugerido: 100.
- Sin datos personales: la app **no** manda payload, `detail` del error ni nombres. El backend
  ya conoce usuario y dispositivo por el token; puede enriquecer con el envío si `id` coincide
  con un intento registrado.

### 2. Visibilidad en la torre de control

- Listar las fallas recientes por usuario/dispositivo/envío (filtro por `kind` y `problem_code`).
- Idealmente, una alerta cuando un mismo dispositivo acumula N rechazos en poco tiempo
  (dispositivo con reloj mal, app vieja con `kind` obsoleto, etc.).

### 3. Contrato

Agregar el endpoint a `openapi/v1.yaml` (tag `execution` o uno nuevo `telemetry`) para que la app
regenere el cliente (regla: no se escriben DTOs a mano).

## Qué hace hoy la app (sin esperar al backend)

- Política de reintentos: sin red y 401 no gastan intentos (la fila espera señal o el próximo
  login); 429/5xx suman `attempts` con backoff exponencial (5 s → 10 min) y a los 50 la fila pasa
  a `failed` (`retries_exhausted`); el resto de 4xx pasa a `failed` (`rejected`).
- Cada `failed` se reporta al `FailureReporter` (hoy no-op; se conectará a Crashlytics).
- Las filas `failed` se purgan a los 7 días o al cerrar sesión (las pendientes nunca).

Cuando exista el endpoint, la app implementará un `FailureReporter` que acumule los eventos en la
base local y los suba en lote con este endpoint durante el drenado.
