# Auditoría completa de la app → pedidos al backend (priorizados)

Fecha: 2026-11-12 · Origen: auditoría de TODA la app (chofer, tienda, transportista,
supervisor, ajustes, core) pedida por el dueño: *"si algo es solo local, que el backend
lo implemente; si el servicio trae todo, pedile paginación; no te conformes"*.

Cada punto: **qué falta**, **endpoint/campo propuesto** y **qué se rompe hoy**.
Se pide **confirmación por punto** cuando esté desplegado.

---

## P0 — Bloqueantes y seguridad

### 1. El estado del pedido NUNCA avanza → "Pedidos por preparar" arrastra todo (BLOQUEANTE)
Datos de staging: `?status=PLANNED` → **216**, `?status=RECEIVED` → **168** (384 en la
worklist, incluidos los de **octubre**); `?status=IN_EXECUTION` → **0**.
**SCZ-261111-01 sigue en `PLANNED`** con etiquetas emitidas, camión 904U10 asignado y
carga registrada. El payload de `/app/shipments` no trae `vehicle_id`, `assigned_at`,
`prepared_at` ni `labels_emitted` → **la app no puede saber qué ya se preparó**.

Pedido (preferible 1a + 1c):
- **1a.** Que el estado avance al asignar vehículo (`POST /app/orders/{n}/vehicle`, ya
  consumido) y/o al emitir+cargar: a `IN_EXECUTION` o un estado nuevo `PREPARED`/`LOADED`.
- **1b.** Alternativa: filtro `GET /app/shipments?pending_preparation=true`.
- **1c.** Exponer el avance por ítem: `vehicle_id`, `plate`, `assigned_at`, `prepared_at`,
  `labels_emitted_count` (además permite mostrar "Asignado a 904U10" en la tarjeta).
- **1d.** `status` hoy es **case-sensitive en MAYÚSCULAS** (`?status=planned` → 422).
  Aceptar ambos evita un pie fácil de pisar.

### 2. El transportista externo ve y opera liquidaciones AJENAS (fuga de datos financieros)
`carrier_guard.dart:21-56` + `carrier_controllers.dart:22-34`: el usuario **elige de una
lista de TODOS los carriers** cuál es "él" (estado solo en memoria) y con ese `carrier_id`
consulta `/app/carriers/settlements` y puede **aprobar / disputar / marcar como pagada**.
Pedido:
- `GET /app/auth/me` → `carrier: {id, name, tax_id}` para el rol transportista (igual que
  `node` para tienda).
- Scope server-side: `GET /app/carriers/settlements` **ignora** `carrier_id` y devuelve solo
  las del usuario; `approve/dispute/pay` → **403** si no es suya.
- Definir si `pay` corresponde al proveedor o a finanzas (si es finanzas, negarlo por ability).

### 3. POD de recojo en tienda manda `photo_path: "pendiente"` (dato falso)
`pickup_pod_screen.dart:185` → `record_pod.dart:31-41`. La foto real sube por otra cola
(`POST /app/deliveries/photos`) sin correlación con el POD.
Pedido: `PATCH /app/deliveries/{shipmentId}/proof-of-delivery {photo_path}` idempotente, **o**
aceptar en el POD un `evidence_client_id` (uuid que genera la app) que la foto también mande.
**Riesgo**: si se implementa la validación ya pedida ("`photo_path` debe existir en el disco
de evidencia"), el POD de tienda se va a **422 → la cola lo descarta → entrega perdida**.

---

## P1 — Funcionalidad que hoy es SOLO LOCAL (se pierde / el backend no se entera)

### 4. El transportista no sabe qué recoger: no hay viaje/carga asignada
Escanea a ciegas (`carrier_pickup_screen.dart:35-61`), la sesión vive en una `List` en memoria.
Pedido: `GET /app/carriers/me/assignments` → `[{trip_id, corridor_from, corridor_to,
scheduled_at, status, shipments:[{shipment_id, external_id, customer_name, destination_node,
units:[{unit_id, sku, product_name}]}], expected_units_count}]` con cursor; +
`POST /app/carriers/trips/{id}/start|close`.

### 5. Llegada a la parada (`arrived_at`) es 100% del cliente
La geocerca marca "Llegaste" en la app pero **no se informa**; en `execution_client.dart` no
existe `arrive`.
Pedido: `POST /app/deliveries/{shipmentId}/arrived {lat,lng,occurred_at,source:geofence|manual}`
+ `Idempotency-Key`; persistir `DriverRouteStop.arrived_at`.
**Es prerrequisito** de `avg_stop_minutes` / `on_time_rate` de los KPIs ya pedidos.

### 6. Abrir/cerrar la ruta del día
"Finalizar ruta" solo registra odómetro (`driver_route_screen.dart:113-128`); `DriverRoute.status`
nunca pasa a `completed`.
Pedido: `POST /app/vehicles/{id}/route/start` y `/route/close` `{odometer_km, occurred_at, lat, lng}`,
idempotentes, devolviendo `started_at`/`closed_at`/`status`.

### 7. La ubicación en estante se tira a la basura
`shelf_locations_notifier.dart:3-5` — comentario textual: *"No hay endpoint: se guarda en memoria"*.
Pedido: `POST /app/node-receptions/{shipmentId}/units/{unitId}/location {node_id, location,
occurred_at}` (idempotente, aceptar lote `{location, unit_ids:[…]}`) y devolver `location` en
`UnitTracking`/`NodeReceptionUnit`.

### 8. No hay preferencias de usuario: todo se pierde al reinstalar y no viaja entre teléfonos
`/app/settings/{key}` es solo lectura y de a una clave, y **no se consume**. Hoy son locales:
widgets del inicio, alto contraste, vibración al escanear, simbología, credenciales de impresora.
Pedido: `GET/PUT /app/me/preferences` (merge en PUT, `updated_at` para conflictos) +
`GET /app/app-config` (claves públicas de etiqueta y tunables: radio de geocerca, intervalos)
para no sacar release por cambiar un número.

### 9. Notificaciones sin estado de lectura
No existe `read_at` ni endpoint. La campana no puede mostrar badge real y marcar leído en un
teléfono no se refleja en otro.
Pedido: `read_at` por usuario, `POST /app/notifications/{id}/read`, `/read-all`, y
`meta.unread_count`.

### 10. Abrir recepción: el nodo de ORIGEN y el manifiesto los define el teléfono
`open_reception_panel.dart:49,63-87` (dropdown con TODOS los nodos; `expected_unit_ids` armado
en el cliente).
Pedido: `POST /app/node-receptions` que acepte `{shipment_id, occurred_at}` y **derive** origen,
destino y `expected_unit_ids` server-side (mismo patrón ya aceptado para emisión por orden).

### 11. Conciliar faltantes/sobrantes sin motivo ni evidencia
Pedido: aceptar `{notes?, missing:[{unit_id, reason}], surplus:[{unit_id, belongs_to_shipment_id?}],
photo_path?}` con enum de motivos, y devolverlo en `NodeReceptionView`.

---

## P2 — Escala y eficiencia (paginación, N+1, lotes)

### 12. Telemetría: ~2.900 POST por chofer por día
`truck_tracking_service.dart:494-522` encola **un POST por fix** (`/app/tracking/shipments/{id}/position`).
Ya existe `POST /app/telemetry/pings` (lote) y el datasource está cableado pero **muerto**.
Pedido (una): (a) confirmar que `/app/telemetry/pings` alimenta también el seguimiento por ENVÍO
(ETA, breadcrumbs) → la app migra y baja a ~100 req/día; **o** (b)
`POST /app/tracking/shipments/{id}/positions {positions:[{lat,lng,reported_at,speed_kph,accuracy_m}]}` (202).

### 13. Escaneos en lote
La cola drena 1 request por fila (`offline_queue.dart:224-300`). Un día sin señal = cientos de POST.
Pedido: `POST /app/deliveries/scans/batch {items:[{idempotency_key, kind, occurred_at, payload}]}`
→ **207** con resultado por ítem (`accepted|duplicate|rejected`). Y `Retry-After` en los 429.

### 14. POD en lote + vínculo real con la foto
Hoy **un POST por bulto** (`pod_screen.dart:478-504`): 10 bultos = 10 POST en la peor red del flujo.
Pedido: que `POST /app/deliveries/proof-of-delivery` acepte `unit_ids:[…]` (o
`POST /app/deliveries/{shipmentId}/complete`) con una sola confirmación/firma/GPS, idempotente, y
que acepte `evidence_ids` devueltos por la subida de fotos.

### 15. `Idempotency-Key` en `POST /app/deliveries/photos`
Es el **único** write de campo sin la cabecera; la cola reintenta por diseño → **evidencia duplicada**.

### 16. El tablero del supervisor baja TODA la colección histórica de envíos
`supervisor_remote_data_source.dart:119-129` llama sin paginar **a propósito** (con 50 las métricas
se cortaban) y cuenta estados en el teléfono.
Pedido (preferible b): (a) `?date=`/`date_from`/`date_to` + `status[]` múltiple + `meta.count_by_status`;
**(b)** `GET /app/shipments/summary?date=` → `{by_status:{…}, active_plans, open_alerts, generated_at}`.

### 17. `GET /app/telemetry/fleet/live` sin placa ni chofer, y repolling completo cada 30 s
La app baja **toda la flota** solo para traducir UUID→placa; los camiones sin placa quedan fuera.
Pedido: `plate` + `driver_name` en `VehicleLive`, `Alert` y `Plan`; `ETag`/`If-None-Match` (304) o
`?since=<iso>`; opcional `?bbox=`.

### 18. `GET /app/vehicles/{id}/deliveries` no trae con qué nombrar el envío
La pantalla de carga muestra literalmente **"Envío 1", "Envío 2"**.
Pedido: `order_reference`, `customer_name`, `address` corta, `units_total`, `units_loaded`;
+ paginación.

### 19. Total de BULTOS por parada (hoy se deduce de la cantidad de productos)
El POD calcula el total esperado como **suma de `items[].quantity`**; cantidad de producto ≠
cantidad de bultos → el POD puede **bloquear o dejar cerrar mal**.
Pedido: `units_total` y `unit_ids:[…]` en `DriverRouteStop` (y en `Delivery`). Elimina además un N+1.

### 20. Paginación faltante (lista concreta)
- `GET /app/carriers/settlements`: sin `page/per_page/cursor` **ni periodo** → histórico de años en
  una sola respuesta. Pedido: cursor + `period_from/period_to`.
- `GET /app/telemetry/alerts`: sin paginación ni rango → se acumulan para siempre.
  Pedido: cursor + `from/to` + `meta.total`/`unacknowledged_total`.
- `/app/notifications/all`: solo `limit`; "Ver más" **re-descarga todo** (tráfico cuadrático) y topa
  en 150. Pedido: `cursor`/`before_id` + `per_page` + `meta.next_cursor`.
- `GET /app/fleet/pre-trip-checklists`: sin `from/to` ni paginación **y sin orden garantizado**;
  el recordatorio del inicio baja TODO el historial en cada arranque.
  Pedido: `from/to` + paginación + orden, y `GET /app/fleet/pre-trip-checklists/latest?vehicle_id=`.
- `GET /app/fleetops/{odometer,refuels,maintenance/orders,departures}`: tienen `from/to` pero no
  paginación ni orden definido. Pedido: `per_page`+`cursor`, `order=desc`.
- `GET /app/fleetops/maintenance/due`: **sin un solo parámetro** → el chofer baja el mantenimiento de
  toda la flota. Pedido: `?vehicle_id=`, `?urgency=`, paginación.
- `GET /app/plans`: solo `date`. Pedido: `page/per_page` + `status`.
- `GET /app/access/users`: solo `status`, sin búsqueda ni paginación (antes de que la app lo use).

### 21. La lista de la tienda no trae el estado de recepción → o no muestra nada o es N+1
Pedido: en cada ítem de `GET /app/shipments` (o `GET /app/node-receptions?node_id=&status=open`)
un `reception: {status, expected_count, received_count, missing_count, surplus_count, opened_at}`.

---

## P3 — Contrato y calidad de datos

### 22. `Shipment.delivery_mode` (domicilio vs recojo en tienda)
Hoy "Recojo en tienda" y "Recepción de mercadería" usan el **mismo** listado → el mostrador ofrece
entregar pedidos que en realidad reparte un chofer (**POD indebido**).
Pedido: `delivery_mode: [home_delivery, store_pickup]` (+ `pickup_code` si existe) y filtro en
`/app/shipments`.

### 23. Endpoints implementados pero FUERA del `openapi/v1.yaml`
2FA y reseteo de password (`/app/auth/2fa/*`, `/app/auth/password/*`), `POST /app/deliveries/evidence`,
`GET /app/labels/{id}/resolve`, emit por orden. La app los llama con **Dio crudo**, violando la regla 5
del proyecto. Pedido: publicarlos (con los dos shapes de la 200 del login: éxito y `two_factor_required`).

### 24. Schemas sin tipar
`GET /app/fleetops/maintenance/due` y `utilization` devuelven objetos libres: la app **adivina claves**
(`plate` o `vehicle_plate`, `remaining_km`…). Si se renombra una clave, **la pantalla queda en blanco
sin error**. Pedido: schemas con nombre. (Además de los `DataN` anónimos ya pedidos.)

### 25. `lat`/`lng` obligatorios → se guarda `0,0` como posición real
En `ReceiveUnitAtNodeRequest` y `ProofOfDeliveryRequest`. Sin señal en interiores se contamina toda
auditoría geográfica. Pedido: nullable (o `location:{lat,lng,accuracy_m,captured_at}` opcional).

### 26. Dirección estructurada
La app parsea texto libre comparando contra un diccionario de ciudades bolivianas embebido para que
entre en pantalla. Pedido: `address_parts {street, number, neighborhood, reference, city}` o
`short_address`.

### 27. Plantilla y criticidad del checklist viven en la app
Los 10 ítems y cuáles son críticos están **hardcodeados**; el "NO apto para salir" es solo un
snackbar: **el backend no bloquea nada**. Pedido: `GET /app/fleet/checklist-template?vehicle_id=` y que
el POST devuelva `fit_to_dispatch` + marque el vehículo no operativo.

### 28. `GET /app/devices` no distingue teléfonos
`DeviceListItem` = uuid/platform/name/last_seen/revoked y la app manda `name:'App interna'` fijo → N filas
idénticas, no se sabe cuál revocar. Pedido: `model`, `os_version`, `app_version`, `last_ip`/ciudad,
`current:true`. (Mandar el modelo real es arreglo de la app.)

### 29. `GET /app/fleet/my-crew`: `date` declarado `date-time` en el spec → 422
Por eso esa llamada va con Dio crudo. Pedido: declararlo `format: date`.

---

## Ya pedido y SIGUE ABIERTO (se re-pide)

- **`Shipment.destination_node_id` sin poblar** (`2026-10-16-pendientes-consolidados.md` #1):
  llega `null` → **"Recepción de mercadería" y "Recojo en tienda" salen VACÍAS**. Bloqueo nº1 del rol tienda.
- **Foto obligatoria del POD server-side** (consolidados #3) — ojo con el punto 3 de arriba.
- **KPIs del día** `GET /app/kpis/daily` (consolidados #5) — se superpone con el punto 16.
- **`POST /app/outbox-failures`** (`2026-10-16-reporte-acciones-rechazadas.md`): el reporter sigue no-op,
  o sea **un rechazo de campo no le llega a nadie**.
- **`X-Min-App-Version` / 426** (`2026-10-16-version-minima-app.md`): la app ya reacciona, el backend nunca
  manda la cabecera.
- **Impresoras por nodo** `GET /app/printers` (`2026-11-11-registro-impresoras-por-nodo.md`): por eso la
  impresora sigue 100% local y se pierde al reinstalar.
- **Schemas anónimos `DataN`** (consolidados #4).
- **"QR del cliente" en recojo en tienda / transportista**: en el chofer ya se quitó; tienda y transportista
  **siguen exigiéndolo** y `confirmation` es requerido. Sin respuesta, el transportista no puede entregar.
- **ETA con tráfico, alertas de desvío/velocidad, breadcrumbs por envío**
  (`2026-11-11-telemetria-seguimiento-roadmap.md`).
- **`DriverRouteStop.destination.type`** (`2026-11-05-ruta-parada-tipo-de-destino.md`).

---

## Lo que arregla la app (sin backend) — compromiso de este lado

1. Scroll infinito en las listas que ya soportan paginación (worklist del preparador, tienda) —
   **después** del filtro del punto 1, si no se pagina sobre 384 pedidos viejos.
2. Pasar `from/to` donde el contrato ya los acepta (refuels, odómetro) — corta el 90% de la descarga.
3. Persistir el espejo local de paradas/bultos resueltos junto a la cola offline (hoy se pierde si el SO
   mata la app).
4. Mandar el modelo real del teléfono en `device.name`; respetar `Retry-After`; preferencias por usuario.
5. Refresh proactivo del token (hoy solo hay un botón manual) para que no se caiga la sesión en una entrega.
6. Esconder acciones financieras y pantallas de oficina por ability en el rol transportista.
7. Sembrar el estado de entrega del mostrador con lo que ya confirmó el servidor (evita PODs duplicados).
