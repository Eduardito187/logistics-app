---
name: backend-audit-2026-11-12
description: "Auditoría completa de la app (nov 2026): 29 pedidos priorizados al backend, qué tomó el backend y qué queda por cablear tras el deploy"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-12T13:16:03.910Z
---

**12-nov-2026.** El dueño pidió auditar TODA la app (no solo el preparador) con el criterio: *"si algo es solo local, que el backend lo implemente; si el servicio trae todo, pedile paginación; no te conformes"*. Se hizo con 3 agentes de solo-lectura (chofer+isla / tienda+transportista / supervisor+core) y quedó en `docs/backend-requests/2026-11-12-auditoria-completa-app-pedidos-priorizados.md` (+ fila en el README). Prioridad que fijó el dueño: **TODO**, en orden contrato → funcionalidad → escala.

**Hallazgos de fondo (los 3 que más dolían):**
1. **`Shipment.status` NUNCA avanzaba** → "Pedidos por preparar" arrastraba **384** pedidos (216 PLANNED + 168 RECEIVED, incluidos los de octubre) y `IN_EXECUTION`=0. Preparar/asignar/cargar no cambiaba nada y el payload no traía `vehicle_id`/`prepared_at`, así que **la app no podía filtrarlo**.
2. **Fuga financiera**: el transportista ELEGÍA de una lista cuál transportista era "él" (estado local) y con eso veía y podía aprobar/disputar/pagar liquidaciones **ajenas**.
3. El POD de tienda mandaba `photo_path:"pendiente"` (inventado) → al validar el backend, la entrega se habría **perdido**.

**El backend cerró TODO el backlog en código** (sin deploy al cierre de la sesión): estado que avanza + backfill + `progress{vehicle_id,plate,assigned_at,prepared_at,execution_status}`; scope server-side de carriers + `carrier` en `/auth/me`; `arrived_at`; route start/close; `/scans/batch` (207); POD con `unit_ids[]`+`photo_paths[]` y `confirmation` OPCIONAL para tienda/transportista (**se acabó el "QR del cliente"**); recepción que deriva origen/manifiesto + ubicación en estante + reconcile con motivo; `/shipments/summary` y `/kpis/daily`; telemetría en lote que SÍ alimenta el seguimiento por envío; `fleet/live` con placa/chofer + ETag/`since`; checklist server-side que **bloquea el vehículo no apto**; notificaciones con `read_at`/`unread_count`; `/me/preferences` + `/app-config`; `outbox-failures`; 426; devices con nombre real; paginación en todo; `ListMeta` único; y "bulto" fuera del OpenAPI.

**Hecho del lado app** (2770 tests verdes, analyze limpio): asignación de vehículo que avisa al backend; scroll infinito en worklist del preparador y listas de tienda; POD multi-producto usando `unit_ids`; foto del POD de tienda encadenada; acciones financieras por ability (fail-closed); `Retry-After`; renovación proactiva de sesión; modo abierto de etiquetas; "producto" en vez de "bulto".

**Pendiente de cablear CUANDO SE DESPLIEGUE** (plan acordado): **regenerar el cliente API UNA SOLA VEZ** con todo junto y después, por tandas: headers nuevos (`X-App-Platform`, `X-Device-Model`, `X-Device-Os-Version`) + 426; notificaciones (migrar de `limit` a `per_page`+cursor, badge, marcar leído); `outbox-failures`; `app-config` + `preferences`; devices; `progress` en la tarjeta ("Asignado a 904U10"); dejar de mandar `carrier_id` y leerlo de `/auth/me`; telemetría en lote; y **sacar la heurística de paginación** (ver [[generated-code-build-caveats]]).

**Actualización 12-nov (cierre de huecos del backend, aún SIN deploy):** el backend cerró más cosas en código + `openapi/v1.yaml`. Novedades que ya me avisó `logistics-5b`:
- ⚠️ **#3 endurecido — POD de tienda offline (RESUELTO por el dueño).** El POD iba a rechazar con **422** (`errors.photo_path`) cualquier `photo_path` falso o faltante, porque el dueño había puesto la foto como obligatoria en el servidor. Eso chocaba con la regla offline-invisible (el POD se encola al instante y la foto viaja después por su cola). **Decisión del dueño (12-nov): opción A** — el POD **siempre responde 200 aunque la foto no haya subido todavía**; el servidor lo marca "pendiente de foto" y liga la evidencia cuando llega después. La foto sigue siendo obligatoria, solo que **asíncrona**: NADA de 422 por "falta foto" ni online ni offline. Del lado app no hay cambio: `_photoPathForPod()` manda el `path` real de `POST /app/deliveries/photos` cuando la subida terminó, u **omite** `photo_path` cuando la foto va a seguir por su cola (ya no manda el `"pendiente"` inventado). El backend también acepta `evidence_ids[]` (evidencia ya capturada del envío). El backend implementa A y recién entonces despliega #3. **A ya está en código (sin deploy):** el POD responde 200 sin foto; si no hay foto la entrega queda `pod_photo_pending: true` (**campo nuevo en `Delivery`/DeliveryState**) y la foto que llega después por `POST /app/deliveries/photos` se liga sola al envío (ahí pasa a false) — **sin cambio del lado app**. Si se manda una referencia de foto, se sigue validando que exista (ruta inventada → 422). Contrato: `ProofOfDeliveryRequest.photo_path` ahora OPCIONAL. **El app NO muestra `pod_photo_pending`** (regla offline-invisible: nunca mostrar "pendiente"); queda como verdad interna/diagnóstico.
- **`delivery_mode` suma `transfer`** (reabastecimiento interno a tienda, source TRANSFER): el mostrador **NO** debe ofrecer entregar un `transfer`. `store_pickup` queda solo para pedidos de cliente. `OrderSource` suma `TRANSFER`.
- `GET /app/shipments?pending_preparation=true` (asignados sin escaneo de preparación).
- `GET /app/plans` trae `plate` y `driver_name`.
- `GET /app/carriers/corridors` (elegir corredor; from/to = los slugs que ya acepta la tarifa + label legible). Settlements: filtro `period_from`/`period_to` + campo `vehicle_class`.
- devices: `last_ip`.
Todo esto entra en la MISMA regeneración única del cliente + tandas de cableado post-deploy.

Ver [[no-label-mutations-rule]], [[vocabulario-producto-no-bulto]], [[carrier-corridor-slugs]], [[label-key-rotation-footgun]], [[native-share-evidence]].
