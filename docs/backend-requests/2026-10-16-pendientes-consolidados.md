# Pedido al backend: pendientes consolidados de la app interna

**De:** app interna (logistics-app) · **Para:** agente/equipo del repo `logistics` (backend)
**Fecha:** 2026-10-16 · **Reemplaza como lista de trabajo** a lo que quedó abierto en los pedidos
anteriores (índice y estado en `README.md` de esta carpeta).

Resumen:

| # | Pedido | Prioridad | Bloquea en la app |
|---|---|---|---|
| 1 | Ingest/SAP debe poblar `Shipment.destination_node_id` | **alta** | lista de la tienda sale vacía |
| 2 | Push 1-a-1 en eventos reales + publicar a topics `role_*` / `node_*` | alta | ningún aviso push llega hoy |
| 3 | Exigir foto en el POD del chofer (server-side) | media | nada (la app ya la exige) |
| 4 | Nombrar los schemas anónimos del openapi | media | regenerar el cliente rompe la app |
| 5 | Endpoint de KPIs del día (supervisor y chofer) | media | pantalla de indicadores (punto 17) |

Todo cambio de contrato, reflejarlo en `openapi/v1.yaml`: la app regenera su cliente desde ahí
(`scripts/regen_api_client.ps1`, ver `docs/cliente-api.md` de la app).

---

## 1. Poblar `Shipment.destination_node_id` desde el ingest / SAP

**Estado:** el contrato ya está (`Shipment.destination_node_id`, filtro `destination_node_id` en
`GET /app/shipments` y, para el rol Tienda, forzado server-side a su nodo). **Falta el dato**: el
schema dice "Null mientras el ingest/SAP no lo pueble" y hoy todos llegan `null`.

**Efecto:** el usuario de tienda ve "Recepción de mercadería" y "Recojo en tienda" **vacías** (por
diseño: el filtro no muestra envíos de otras tiendas). El piloto con tiendas no puede arrancar.

**Pedido:**

1. En la importación de órdenes (`/integrations/sap/orders:import` / `receiveShipment`) y en las
   transferencias de stock SAP, resolver el nodo destino:
   - retiro en tienda → nodo `store` del punto de retiro;
   - entrega a domicilio desde una tienda/CD → nodo que despacha o recibe para la última milla
     (definir con negocio cuál ve la tienda);
   - mapeo por código SAP del centro/almacén → `network_nodes.code`.
2. **Backfill** de los envíos abiertos existentes (comando/migración idempotente).
3. Si no se puede resolver, dejar `null` y registrarlo (log/métrica) para detectar códigos sin
   mapeo, en vez de asignar uno por defecto.

**Criterio de aceptación:** un usuario `tienda` con `node` asignado ve en `GET /app/shipments` los
envíos de su tienda; otro usuario de otra tienda no los ve.

## 2. Push: envío 1-a-1 en eventos reales + topics de la app interna

**Estado:** entregado `PUT /app/devices/current/push-token` y la capacidad
`FcmChannelSender::sendToDevice`. La app ya:

- manda el FID en el login (`device.push_token`) y lo actualiza al rotar (cola offline);
- al iniciar sesión se suscribe a **`role_<backendKey>`** y, si tiene tienda, a **`node_<id>`**
  (y se desuscribe al cerrar sesión). Los `backendKey` son exactamente:
  `role_chofer`, `role_preparador`, `role_tienda`, `role_transportista`, `role_supervisor`;
  `node_<uuid del nodo>` (el `id` de `AppUserProfile.node`).

**Falta:** que algo **publique**. Pedido:

1. **1-a-1** (al dispositivo del usuario, `push_token` del último login/refresh) en estos eventos:

   | Evento | Destinatario |
   |---|---|
   | Ruta/plan asignado o modificado (paradas agregadas/quitadas/reordenadas) | chofer del vehículo |
   | Envío cancelado o reprogramado estando en su ruta | chofer |
   | Tarea de preparación/picking asignada | preparador |
   | Transferencia/envío despachado hacia su tienda; cliente llegó a retirar (si aplica) | tienda (o `node_<id>`) |
   | Entrega fallida / incidente de vehículo / issue de entrega (`POST /app/deliveries/{id}/issues`) | supervisor (o `role_supervisor`) |
   | Documento de flota por vencer (`expiring`) | supervisor / transportista dueño |

2. **Topics** para difusión: publicar a `role_<backendKey>` (avisos generales por rol) y
   `node_<id>` (todo lo de una tienda), con el mismo payload.
3. **Payload** (la app ya lo interpreta): `notification {title, body}` en español +
   `data {notification_id, shipment_id?, message_type}`; al tocar, la app abre la bandeja por
   `notification_id` (o `shipment_id`). Que cada push tenga su fila en `GET /app/notifications`.
4. Si el token es inválido (`UNREGISTERED`), limpiarlo del dispositivo.
5. Mismo proyecto Firebase que la app (ver `docs/firebase-setup.md` de la app; la service account la
   genera quien administre el proyecto).

## 3. Foto obligatoria en el POD del chofer (server-side)

**Estado:** la app **no deja** registrar la entrega del chofer sin foto (sube con
`POST /app/deliveries/photos` y manda `photo_path`/`photo_url` en `ProofOfDeliveryRequest`). Pero en
el contrato ambos son `nullable` y el backend acepta POD sin foto (una versión vieja de la app, otro
cliente o una llamada directa pasan).

**Pedido:**

1. Si quien registra el POD tiene rol **chofer** (o el envío es a domicilio), exigir `photo_path`
   (la referencia durable) → `422` RFC 7807 con `errors.photo_path` si falta.
2. Validar que `photo_path` exista en el disco de evidencia y haya sido subido para ese envío
   (evita reutilizar fotos de otro envío).
3. **Recojo en tienda** (rol tienda) puede seguir sin foto si negocio lo decide; documentarlo en la
   descripción de la operación.
4. Documentarlo en `openapi/v1.yaml` (descripción + respuesta 422). Si se agrega un schema aparte
   para el chofer, la app regenera.

**Ojo con la cola offline:** la app encola el POD y lo reintenta; un 422 lo descarta. Por eso pedimos
que sólo falle cuando realmente falta la foto, no por un `photo_url` vencido (validar `photo_path`).

## 4. Nombrar los schemas anónimos (inline) del openapi

**Problema:** swagger_parser nombra los objetos inline sin nombre como `Data`, `Data2`…`Data28`
(y `MetaN`, `StatusN`, `ErrorN`, `TypeN`…) **por orden de aparición**. Al agregar un endpoint en el
medio del spec la numeración se corre (`Data4` → `Data5`) y el código de la app deja de compilar o,
peor, compila con otro tipo. Ya pasó una vez (renumeramos `Data4→5`, `Data6→7`, `Data21→22`), y el
spec actual con *Sellers* vuelve a mover `Status8` → `Status9` dentro de `Data26`.

**Pedido:** mover cada objeto/enum inline a `components/schemas` con nombre propio y referenciarlo
con `$ref` (es lo que garantiza un nombre estable en el generador; un `title` solo **no** alcanza
con todas las versiones de swagger_parser). Prioridad a los que **la app ya usa** (★).

### `data` inline de respuestas (`DataN`)

| Tipo generado | Endpoint / schema (propiedad `data`) | Campos | Nombre sugerido |
|---|---|---|---|
| `Data` | `POST /app/deliveries/photos` | kind, disk, path, url | `UploadedPhoto` |
| `Data2` | `POST /app/deliveries/{shipmentId}/issues` | shipment_id, type, status | `DeliveryIssueAccepted` |
| `Data3` | `POST /app/fleet/crews` | status, driver_id, vehicle_id, assembled_for | `CrewAssembled` |
| `Data4` | `PATCH /app/fleet/helpers/{helperId}/availability` | status, helper_id, active | `HelperAvailabilityChanged` |
| ★ `Data5` | `POST /app/fleet/pre-trip-checklists` | status, vehicle_id, driver_id, performed_on | `PreTripChecklistRecorded` |
| `Data6` | `PATCH /app/fleet/vehicles/{vehicleId}/status` | status, vehicle_id, new_status | `VehicleStatusChanged` |
| ★ `Data7` | `GET /app/plans/{planId}/eta` | plan_id, status, stops[StopEta] | `PlanEta` |
| `Data8` | `POST /app/sap/stock-transfers` | event_id, shipment_ref, status | `StockTransferEnqueued` |
| `Data9` | `POST /app/sap/stock-transfers/dispatch` | status | `StockTransferDispatchRequested` |
| `Data10` | `GET /app/tracking/shipments/{shipmentId}/units` | shipment_id, units[UnitTracking] | `ShipmentUnitsTracking` |
| `Data11` | `POST /app/tracking/shipments/{shipmentId}/position` | shipment_id, accepted | `PositionAccepted` |
| `Data12` | `GET /channels/tracking/{token}/units` | units[PublicUnit] | `PublicUnits` |
| `Data13` | `POST /integrations/coverage/map:import` | status | `CoverageImportAccepted` |
| `Data14` | `POST /integrations/coverage/map:import-kml` | status | (mismo que `Data13`) |
| `Data15` | `POST /integrations/fleet/documents` | status, owner_type, owner_id, document_type | `FleetDocumentAccepted` |
| `Data16` | `POST /integrations/fleet/drivers` | status, license_number | `FleetDriverAccepted` |
| `Data17` | `POST /integrations/fleet/helpers` | status, name | `FleetHelperAccepted` |
| `Data18` | `POST /integrations/fleet/vehicles` | status, plate | `FleetVehicleAccepted` |
| `Data19` | `POST /integrations/network/nodes` | code | `NodeAccepted` |
| `Data20` | `POST /integrations/sap/stock-transfers/acknowledge` | event_id, status | `StockTransferAcknowledged` |
| `Data21` | `POST /integrations/tracking/shipments/{shipmentId}/position` | shipment_id, accepted | (mismo que `Data11`) |
| ★ `Data22` | schema `AcceptedEnvelope.data` (≈50 operaciones) | accepted | `Accepted` |
| `Data23` | schema `AdvanceCascadeEnvelope.data` | notification_id, status | `CascadeAdvanced` |
| `Data24` | schema `OutboxActionEnvelope.data` | id, status | `OutboxAction` |
| `Data25` | schema `QueuedNotificationEnvelope.data` | shipment_id, message_type, status | `QueuedNotification` |
| `Data26` | schema `ReceiveShipmentAccepted.data` | source, external_id, status | `ShipmentReceipt` |
| `Data27` | schema `SetSettingAccepted.data` | accepted, key | `SettingAccepted` |
| `Data28` | schema `SettingEnvelope.data` | key, value | `SettingValue` |

### `meta` inline (`MetaN`)

| Tipo | Dónde | Campos | Sugerencia |
|---|---|---|---|
| `Meta` | `GET /app/plans` | date, count | `PlanListMeta` |
| `Meta2/3/4/7` | respuestas SAP (`material-mappings`, `stock-transfers`, `dispatch`, `acknowledge`) | message | un único `MessageMeta` |
| `Meta5/6/11/12/13/14/17` | `GET /app/vehicles/{id}/deliveries`, `sap/orders:import`, colecciones `Leg`, `MaterialMapping`, `Node`, `OperationalCorridor`, `StockTransfer` | count | un único `CountMeta` |
| `Meta8/9` | `AvailableSlotCollection`, `PromiseOfferCollection` | count? | `CountMeta` |
| `Meta10` | `CapacityCalendarEnvelope` | date?, count? | `CapacityCalendarMeta` |
| `Meta15` | `OutboxMessagePage` | total, page, per_page, last_page | `OffsetPageMeta` |
| `Meta16` | `SettingHistoryEnvelope` | key?, count? | `SettingHistoryMeta` |

### Enums y otros inline

| Tipo | Dónde | Valores / campos | Sugerencia |
|---|---|---|---|
| `Status2` | `Data2.status` | REPORTED | `DeliveryIssueStatus` |
| `Status3` | `Data8.status` | ENQUEUED | `StockTransferEnqueueStatus` |
| `Status4` | `Data9.status` | DISPATCH_REQUESTED | (enum del dispatch) |
| `Status5` | `Data20.status` | ACKNOWLEDGED | (enum del acknowledge) |
| `Status`, `Status6` | enums inline de estado de usuario (`Status6` = `AppAccessUsersRequestBody.status`) | active, suspended(, invited) | `AppUserStatus` |
| `Status7` | estado de acceso/token | active, revoked | `AccessStatus` |
| `Status8` | `Data26.status` | accepted | `ShipmentReceiptStatus` |
| `Type` | `AppVehiclesVehicleIdIncidentsRequestBody.type` | BREAKDOWN, ACCIDENT | `VehicleIncidentType` |
| `Type2` | `Features` | Feature | (GeoJSON) |
| `Enum0` | multipart de `POST /app/deliveries/photos` (`kind`) | pod, damage | `PhotoKind` (reusar el de `Data.kind`) |
| `Error2…Error9` | `CapacityError`, `CoverageError`, `ErrorEnvelope`, `ExecutionError`, `LabelsError`, `PlanningError`, `PromiseError`, `ShipmentsError` | code/type, message | un `ErrorBody` común |
| `Items2`, `Load2` | `RegisterDepartureRequest.load` | description, weight_kg, items[name, qty] | `DepartureLoad`, `DepartureLoadItem` |
| `Items3` ★ | `DriverRouteStop.items` | sku, name, quantity, image_url | `DriverStopItem` |
| `Stops2` | `GeneratePlanProposalRequest.stops` | shipment_id, latitude, longitude | `PlanProposalStop` |

Además: `meta` de varias respuestas se genera como `MetaSealed` **no-nullable** con constructor
opcional (no compila; la app lo parchea a `MetaSealed?` al generar). Marcarlo `nullable: true` o no
`required` de forma consistente.

**Criterio de aceptación:** agregar un endpoint nuevo al spec no cambia ningún nombre de tipo
existente en el cliente generado (la app lo verifica con `scripts/regen_api_client.ps1 -DryRun`, que
avisa si algún `DataN` cambió).

## 5. KPIs del día para supervisor y chofer

Para la pantalla de indicadores (punto 17 del plan de la app). Hoy la app tendría que bajar todas
las entregas (`GET /app/vehicles/{id}/deliveries`, planes, etc.) y calcular en el teléfono: lento,
inconsistente con los reportes y imposible para el supervisor (muchos vehículos).

**Propuesta:** `GET /app/kpis/daily`

- Query: `date` (YYYY-MM-DD, default hoy en zona `America/La_Paz`), opcional `node_id`,
  `vehicle_id`, `driver_id` (sólo supervisor).
- Alcance server-side por rol: **chofer** → sólo lo suyo (ignora filtros); **supervisor** → todo o lo
  filtrado; **tienda** → su nodo (opcional, si se habilita).
- Respuesta (schema con nombre, p. ej. `DailyKpis`):

```yaml
DailyKpis:
  type: object
  required: [date, scope, deliveries_total, deliveries_completed, deliveries_failed,
             deliveries_pending, rejections, avg_stop_minutes, generated_at]
  properties:
    date: { type: string, format: date }
    scope: { type: string, enum: [driver, fleet, node] }
    deliveries_total: { type: integer }        # paradas planificadas del día
    deliveries_completed: { type: integer }    # con POD
    deliveries_failed: { type: integer }       # entrega fallida (POST /app/deliveries/failed)
    deliveries_pending: { type: integer }
    rejections: { type: integer }              # bultos/pedidos rechazados por el cliente
    avg_stop_minutes: { type: number, nullable: true }   # llegada→cierre por parada
    on_time_rate: { type: number, nullable: true }       # 0..1 dentro de la ventana prometida
    failed_by_reason:                          # top motivos de entrega fallida
      type: array
      items:
        type: object
        required: [reason, count]
        properties:
          reason: { type: string }
          count: { type: integer }
    by_driver:                                 # sólo supervisor; vacío para chofer
      type: array
      items:
        type: object
        required: [driver_id, driver_name, completed, failed, pending]
        properties:
          driver_id: { type: string, format: uuid }
          driver_name: { type: string }
          vehicle_plate: { type: string, nullable: true }
          completed: { type: integer }
          failed: { type: integer }
          pending: { type: integer }
          avg_stop_minutes: { type: number, nullable: true }
    generated_at: { type: string, format: date-time }
```

Notas:

- Definir con negocio qué cuenta como **rechazo** (¿motivo de entrega fallida "cliente rechaza"?,
  ¿bultos rechazados en el POD?) y documentarlo en la descripción.
- `avg_stop_minutes`: desde la llegada a la parada (geocerca o primer escaneo de descarga) hasta el
  POD/fallida. Documentar la definición.
- Puede ser cacheado (1–5 min); la app lo refresca al abrir la pantalla y con pull-to-refresh.
- Rol con permiso: ability nueva (p. ej. `kpis.read`) asignada a chofer y supervisor.
