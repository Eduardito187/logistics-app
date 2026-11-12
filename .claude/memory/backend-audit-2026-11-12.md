---
name: backend-audit-2026-11-12
description: "Auditoría completa de la app (nov 2026): 29 pedidos priorizados al backend, qué tomó el backend y qué queda por cablear tras el deploy"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-12T08:44:56.083Z
---

**12-nov-2026.** El dueño pidió auditar TODA la app (no solo el preparador) con el criterio: *"si algo es solo local, que el backend lo implemente; si el servicio trae todo, pedile paginación; no te conformes"*. Se hizo con 3 agentes de solo-lectura (chofer+isla / tienda+transportista / supervisor+core) y quedó en `docs/backend-requests/2026-11-12-auditoria-completa-app-pedidos-priorizados.md` (+ fila en el README). Prioridad que fijó el dueño: **TODO**, en orden contrato → funcionalidad → escala.

**Hallazgos de fondo (los 3 que más dolían):**
1. **`Shipment.status` NUNCA avanzaba** → "Pedidos por preparar" arrastraba **384** pedidos (216 PLANNED + 168 RECEIVED, incluidos los de octubre) y `IN_EXECUTION`=0. Preparar/asignar/cargar no cambiaba nada y el payload no traía `vehicle_id`/`prepared_at`, así que **la app no podía filtrarlo**.
2. **Fuga financiera**: el transportista ELEGÍA de una lista cuál transportista era "él" (estado local) y con eso veía y podía aprobar/disputar/pagar liquidaciones **ajenas**.
3. El POD de tienda mandaba `photo_path:"pendiente"` (inventado) → al validar el backend, la entrega se habría **perdido**.

**El backend cerró TODO el backlog en código** (sin deploy al cierre de la sesión): estado que avanza + backfill + `progress{vehicle_id,plate,assigned_at,prepared_at,execution_status}`; scope server-side de carriers + `carrier` en `/auth/me`; `arrived_at`; route start/close; `/scans/batch` (207); POD con `unit_ids[]`+`photo_paths[]` y `confirmation` OPCIONAL para tienda/transportista (**se acabó el "QR del cliente"**); recepción que deriva origen/manifiesto + ubicación en estante + reconcile con motivo; `/shipments/summary` y `/kpis/daily`; telemetría en lote que SÍ alimenta el seguimiento por envío; `fleet/live` con placa/chofer + ETag/`since`; checklist server-side que **bloquea el vehículo no apto**; notificaciones con `read_at`/`unread_count`; `/me/preferences` + `/app-config`; `outbox-failures`; 426; devices con nombre real; paginación en todo; `ListMeta` único; y "bulto" fuera del OpenAPI.

**Hecho del lado app** (2770 tests verdes, analyze limpio): asignación de vehículo que avisa al backend; scroll infinito en worklist del preparador y listas de tienda; POD multi-producto usando `unit_ids`; foto del POD de tienda encadenada; acciones financieras por ability (fail-closed); `Retry-After`; renovación proactiva de sesión; modo abierto de etiquetas; "producto" en vez de "bulto".

**Pendiente de cablear CUANDO SE DESPLIEGUE** (plan acordado): **regenerar el cliente API UNA SOLA VEZ** con todo junto y después, por tandas: headers nuevos (`X-App-Platform`, `X-Device-Model`, `X-Device-Os-Version`) + 426; notificaciones (migrar de `limit` a `per_page`+cursor, badge, marcar leído); `outbox-failures`; `app-config` + `preferences`; devices; `progress` en la tarjeta ("Asignado a 904U10"); dejar de mandar `carrier_id` y leerlo de `/auth/me`; telemetría en lote; y **sacar la heurística de paginación** (ver [[generated-code-build-caveats]]).

Ver [[no-label-mutations-rule]], [[vocabulario-producto-no-bulto]], [[carrier-corridor-slugs]], [[label-key-rotation-footgun]].
