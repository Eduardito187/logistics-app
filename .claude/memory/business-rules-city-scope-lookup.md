---
name: business-rules-city-scope-lookup
description: "nov 2026 — reglas del dueño: personal por ciudad (departamento) y almacén central; alcance por rol; 'Consultar pedido' para TODOS; tienda solo entrega al cliente; chofer sale N veces al día con inspección y odómetro por salida"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-16T16:42:35.820Z
---

Reglas de negocio que fijó el dueño el 2026-11-14 (cruzan todo el proyecto):

1. **Todo el personal va asignado a un departamento (ciudad de Bolivia).** Una ciudad puede tener
   **almacén central**; no todas lo tienen.
2. **Preparador:** NO prepara pedidos de otra ciudad, pero SÍ puede escanear su etiqueta para ver la info.
3. **Tienda:** solo ve lo que SALE o ENTRA a su tienda (sea cual sea la otra ciudad). **Solo entrega al
   cliente final**: la llegada del pedido la marca el CHOFER ("Entregar en tienda"). Se quitó "Recepción de
   mercadería" del rol (tarjeta, pestaña central, acceso directo; el widget del inicio apunta a
   `/store/pickup`). Las pantallas de recepción quedaron en el código sin acceso y su e2e des-registrado.
4. **Chofer:** solo los pedidos que le asignaron.
5. **TODOS los roles tienen el escáner** para ver información de cualquier pedido, puedan procesarlo o no.
6. Si el cliente va a la tienda a preguntar, la tienda busca el pedido y le dice estado y **a cuántas
   paradas** está.
7. **El chofer sale N veces al día**, con el mismo camión u otro. Inspección y odómetro (salida y llegada)
   van por **cada salida**.

**App (hecho 2026-11-14):**
- `lib/features/lookup/`: "Consultar pedido" (`/lookup`, tarea `order-lookup` con los 6 roles). Escanear
  etiqueta o código → `OrderStatusCard(order: OrderLookupItem)`. Usa la consulta ABIERTA
  `GET /app/orders/lookup?q=` (`shipments.lookupOrders`; 404 = sin resultados → lista vacía). La etapa la
  CALCULA el servidor (`tracking.stage`: received/planned/prepared/onTheWay/atStore/delivered/failed/
  cancelled) y la app solo la traduce (`orderStageLabel`); NO deducirla en la app. Muestra
  `tracking.stopsBefore` ("Está a N paradas de llegar" / "Es la próxima parada del camión"), ETA, placa,
  hitos con fecha y "Solo consulta" si `canProcess == false`. El lookup de etiqueta vive en
  `lib/core/labels/label_lookup.dart`. Solo lectura.
- Tienda: si el pedido buscado no es un recojo listo → botón "Consultar estado del pedido".
- Odómetro con `route_id` (salida en el checklist, llegada al cerrar); `arrivalRecordedForCurrentTrip`
  exacto por `routeId` cuando el backend etiqueta las lecturas, por hora si no.
- Backend ya soporta varias rutas por camión y día (una ABIERTA a la vez; cada salida = otro
  `DriverRoute.id`) → la inspección por `route_id` cubre la segunda salida.

**Tanda ciudad/alcance del backend (2026-11-14, regenerado, sin deploy):** el dueño confirmó que se opera
por ciudad (origen O destino) y que consultar/escanear queda abierto. El ALCANCE LO APLICA EL SERVIDOR (403
`out_of_scope_city|node|assignment`, se muestra el `detail`); usuario sin ciudad = sin restricción. En la app:
- Admin → Personal: filtro por ciudad / "Sin ciudad asignada", ciudad en tarjeta y ficha, y se asigna desde
  "Editar datos personales" (con tienda asignada la ciudad la define la tienda: no se elige).
  `departmentLabel`/`departmentOf`/`staffDepartments` en `staff_labels.dart`.
- **Trampa:** `PUT /app/staff/{id}/profile` BORRA los campos que llegan en null y el cuerpo generado manda
  todos → `updateStaffProfile` va por Dio directo solo con los campos del formulario.
- Chofer "Entregar en tienda": botón "Faltan productos" (tras escanear al menos uno) → motivo → manda
  `missing_units` en el `store-drop`. Solo si la parada trae `unit_ids`.
- Consultar pedido: "Cochabamba → La Paz" si origen ≠ destino (`orderTripText`).
- No cableado aún: `route_id`/`route_status` de `my-crew`.
- **Ciudad del usuario en la sesión + filtro defensivo de la worklist (16-nov-2026):** `/app/auth/me` y el
  login YA traían `user.city`/`city_name` pero la `Session` los tiraba → agregados `Session.city`/`cityName`
  (persistidos, restaurados, propagados en signIn/applyProfile/refresh; los 2 llamadores de `applyProfile`
  —auth_repo y realtime_hub— pasan `me.user.city`). `orders_worklist_controller` ahora **oculta un pedido
  SOLO si sabe la ciudad del usuario Y el `origin_department` del pedido Y difieren** (fail-open en nulls,
  igual que el backend): `_inMyCity`/`_scoped`/`_norm`, aplicado en build y loadMore. Así el preparador deja
  de ver otras ciudades aunque el backend no scope-ee. La worklist ya pedía `planned`+`received`, así que un
  plan que no le llega al preparador es del backend (publicar/scopear), no de la app.
- **Read model del backend `DbShipmentProgressReader` (verificado 16-nov-2026):** `GET /app/shipments`
  enriquece `progress` con vehículo/placa con prioridad **entrega real > ruta del chofer > plan SOLO si
  está PUBLISHED**; `prepared_at = COALESCE(MIN(scan PREPARATION), execution_delivery.created_at)`. El
  "asignar" de la app (`POST /app/orders/{ref}/vehicle` → `AttachShipmentToRoute` + **`OpenDelivery`**) crea
  la entrega, así que `progress.vehicleId` Y `progress.preparedAt` quedan seteados al instante (y entre
  reinicios). Consecuencias cableadas en la app: (1) el seed de "Cambiar camión" en `OrderPreparationScreen`
  funciona porque el backend devuelve `progress.vehicleId`; (2) la worklist oculta DURABLEMENTE lo ya
  preparado por `progress.preparedAt/loadedAt/deliveredAt != null` (`_alreadyHandled`), reemplazando el
  "asignado local" de sesión que se perdía al reiniciar → el pedido ya no reaparece con "Asignar". OJO: un
  pedido solo pre-asignado por un **plan publicado** trae `vehicleId` pero `preparedAt == null` → se SIGUE
  mostrando (el preparador aún debe prepararlo), por eso no se oculta por `vehicleId`. Si un plan creado y
  asignado NO se publica, el backend no adjunta su vehículo → se ve "Asignar": hay que **publicar el plan**.
- **CONFLICTO abierto `pending_preparation` (16-nov-2026):** el backend ofreció un filtro server-side
  autoritativo `GET /app/shipments?pending_preparation=true` que (según su prueba en staging: 130, 0 con
  entrega) EXCLUYE los pedidos ya asignados. PERO el openapi (`v1.yaml` ~5126-5128, y el cliente generado)
  describe lo OPUESTO: "true = only ASSIGNED shipments whose delivery has no PREPARATION scan yet ... Not
  applied to meta.count_by_status". NO se cableó el parámetro por esa contradicción (si el deploy sigue el
  spec, saldrían solo los asignados). El #3 queda cerrado igual por el filtro client-side (`_alreadyHandled`
  por `progress.preparedAt`). Para adoptar el server-side, el backend debe: (1) corregir la descripción del
  openapi + SPEC ESTABLE, (2) confirmar que meta.hasMore/count respeta el filtro (si no, rompe la paginación
  por hasMore de la worklist), (3) decir si combina con `status=planned/received` o lo reemplaza. Pedido
  enviado a logistics-e8.
- **RESUELTO (16-nov-2026):** el backend corrigió la descripción del openapi (ahora dice la verdad: true =
  PLANNED/IN_EXECUTION SIN entrega abierta = por preparar; la paginación SÍ respeta el filtro, solo
  `meta.count_by_status` lo ignora; va SOLO sin status, pending_preparation ya implica PLANNED/IN_EXECUTION).
  **DECISIÓN DEL DUEÑO:** el preparador TAMBIÉN ve los pedidos `received` que aún no entraron a ningún plan
  ("también los recibidos sin plan"). Como `pending_preparation=true` EXCLUYE los received, NO se adopta: la
  worklist se queda con `received` + `planned` (query por-estado) + ocultar client-side lo ya preparado por
  `progress.prepared_at`. El #3 queda cerrado así. Regen del cliente: solo refresca la descripción (sin
  cambio de shape), lo corre el dueño cuando quiera. Ver [[owner-decisions-are-final]].

**Pendiente del backend** (`docs/backend-requests/2026-11-14-ciudades-alcance-por-rol-y-consulta.md`,
enviado a logistics-53): `city` por usuario + catálogo de ciudades con almacén central; **alcance por rol en
el servidor** (hoy el preparador ve pedidos de todo el país; espera confirmación del dueño); confirmar que
nada depende de la recepción de tienda; chofer con camiones distintos el mismo día. **Ya entregado por el
backend (working tree, sin deploy):** la consulta abierta `/app/orders/lookup` con `stops_before` y
`can_process`. Ver [[owner-decisions-are-final]], [[store-pickup-customer-flow]], [[admin-role-in-app]].

**Scope por vehículo + ayudantes (2026-11-15):** el backend endureció GET /app/vehicles/{id}/route y los endpoints por vehículo (deliveries, route start/close, incidents, assemble) para que solo pase OFICINA o tripulante (chofer/ayudante) de ESE vehículo el día; si no, 403 `code: out_of_scope_assignment`. PATCH /app/fleet/vehicles/{id}/status pasó a solo-oficina. En la app NO afecta el uso normal: NO existe login de AYUDANTE (los roles que entran: chofer/preparador/tienda/transportista/supervisor/planificador/admin; los ayudantes son solo nombres de la cuadrilla en `assignment_header.dart`, de solo lectura) y el chofer siempre pide su propio vehículo; la app tampoco usa ese PATCH status. Agregado: ApiException guarda `rawCode` y `isOutOfScopeAssignment` → mensaje 'Este camión no es tuyo hoy…' en vez del genérico (el code aún no está en el enum ProblemCode, cae en $unknown).
