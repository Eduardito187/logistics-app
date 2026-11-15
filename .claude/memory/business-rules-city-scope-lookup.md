---
name: business-rules-city-scope-lookup
description: "nov 2026 — reglas del dueño: personal por ciudad (departamento) y almacén central; alcance por rol; 'Consultar pedido' para TODOS; tienda solo entrega al cliente; chofer sale N veces al día con inspección y odómetro por salida"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-15T00:29:47.212Z
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

**Pendiente del backend** (`docs/backend-requests/2026-11-14-ciudades-alcance-por-rol-y-consulta.md`,
enviado a logistics-53): `city` por usuario + catálogo de ciudades con almacén central; **alcance por rol en
el servidor** (hoy el preparador ve pedidos de todo el país; espera confirmación del dueño); confirmar que
nada depende de la recepción de tienda; chofer con camiones distintos el mismo día. **Ya entregado por el
backend (working tree, sin deploy):** la consulta abierta `/app/orders/lookup` con `stops_before` y
`can_process`. Ver [[owner-decisions-are-final]], [[store-pickup-customer-flow]], [[admin-role-in-app]].
