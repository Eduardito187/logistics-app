# Armado de viajes con sugerencias, rol planificador y textos legibles del plan

- **De:** app interna (logistics-app)
- **Para:** backend (logistics)
- **Fecha:** 2026-11-15
- **Prioridad:** alta (pedido directo del dueño tras probar la app)

## Contexto

El dueño probó el admin en el teléfono y pidió tres cosas:

1. En el detalle de un plan **no quiere ver ningún UUID**: quiere los datos de las relaciones (pedido,
   cliente, dirección, chofer).
2. **Armar viajes desde la app** ("este camión sale y entrega estos 15 pedidos"), intuitivo: al elegir el
   camión se muestran los pedidos **más cercanos al centro de distribución**; al elegir uno, los más cercanos
   a ese; y a medida que arma la lista, **el backend sugiere qué agregar y cómo reordenar** ("que el backend
   piense y razone", un algoritmo de camino más corto). Hay pedidos donde **el cliente eligió la hora**: eso
   debe respetarse.
3. Le gustó la idea de un **rol planificador** (hoy `planning.write` lo tienen supervisor y admin).

## 1. Textos legibles en el plan (sin UUID)

`PlannedStop` (en `Plan.stops`) y `StopEta` (en `GET /app/plans/{id}/eta`) hoy solo traen `shipment_id`. La
app muestra "Envío 01a1c719-…". Pedido — sumar a **ambos** (aditivos, nullable):

```yaml
order_reference: { type: string, nullable: true }   # SO-900001
customer_name:   { type: string, nullable: true }
short_address:   { type: string, nullable: true }   # misma regla que Shipment.short_address
delivery_mode:   { $ref: '#/components/schemas/DeliveryMode' }
units_total:     { type: integer, nullable: true }
time_window:                                         # si el cliente eligió hora
  type: object
  nullable: true
  properties:
    from: { type: string, format: date-time }
    to:   { type: string, format: date-time }
```

Y en `Plan` (lista y ficha): `plate` y `driver_name` ya existen; sumar `origin_node: { id, name } | null`
(de dónde sale el camión) y `distance_km` / `duration_minutes` totales si ya se calculan.

## 2. Armado de viajes con sugerencias

La app va a tener un asistente: **fecha → camión → pedidos**. Necesita que el backend razone:

### 2.a Candidatos ordenados por cercanía

```
GET /app/plans/candidates
  ?date=YYYY-MM-DD            # día del viaje
  &vehicle_id=<uuid>          # para tomar su base (CD) y su capacidad
  &selected[]=<shipment_id>…  # lo ya elegido, en orden (puede venir vacío)
  &q=                         # opcional: buscar por pedido/cliente
  &page / per_page
```

Respuesta: pedidos **planificables ese día** (sin camión, dentro del alcance del usuario), ordenados por
cercanía al **último elegido** (o al CD del camión si `selected` está vacío):

```yaml
data:
  - shipment_id, order_reference, customer_name, short_address, delivery_mode, units_total
    lat, lng
    distance_km_from_anchor: number     # desde el último elegido / el CD
    time_window: { from, to } | null    # hora elegida por el cliente
    fits: boolean                       # ¿entra en lo que le queda al camión?
    fits_reason: string | null          # "supera el peso", "fuera de la ventana horaria"…
    suggested: boolean                  # el backend lo recomienda sumar ahora
    suggested_reason: string | null     # "a 400 m de la parada 3", "misma cuadra"…
meta:
  anchor: { kind: node|shipment, name }
  capacity: { used_units, max_units, used_kg, max_kg }   # lo que tenga el camión
```

### 2.b Orden sugerido (camino más corto respetando ventanas)

```
POST /app/plans/suggest-sequence
{ "date": "YYYY-MM-DD", "vehicle_id": "…", "depart_at": "…", "shipment_ids": ["…"] }
```

Respuesta: el orden que recomienda el backend saliendo del CD (camino más corto; las paradas con
`time_window` se ubican para llegar dentro de su ventana) + ETA por parada + avisos:

```yaml
data:
  ordered_shipment_ids: [ … ]
  stops: [ { shipment_id, sequence, eta_at, within_window: boolean } ]
  distance_km: number
  duration_minutes: number
  changed: boolean            # ¿difiere del orden que mandó la app?
  warnings: [ { code, shipment_id, detail } ]   # window_missed, over_capacity…
```

No guarda nada: es para mostrarle al planificador "te conviene este orden" y que lo acepte o no.

### 2.c Crear / guardar el viaje

Hoy existe `POST /app/plans` (`plan_date`, `vehicle_id`, `depart_at`, `stops[{shipment_id, latitude,
longitude}]`). Pedido: que **`latitude`/`longitude` sean opcionales** (el backend ya conoce la ubicación del
envío) y que respete el orden recibido. Con eso la app crea el plan en borrador, y después usa lo que ya
existe: `POST /plans/{id}/stops`, `PUT /plans/{id}/sequence`, `POST /plans/{id}/publish`.

Falta también **quitar una parada** de un plan sin publicar: `DELETE /app/plans/{planId}/stops/{shipmentId}`.

Dudas para confirmar:
- ¿Un plan PUBLICADO se puede seguir editando (sumar/quitar/reordenar)? Hoy la app lo deja de solo lectura.
- ¿`POST /app/plans` falla si el camión ya tiene plan ese día, o crea otra salida?

## 3. Rol planificador

Nuevo `Role::Planificador = 'planificador'` (la app ya lo reconoce por esa clave). Habilidades sugeridas:
`shipments.read`, `planning.read`, `planning.write`, `fleet.read`, `network.read`, `capacity.read` +
lo necesario para: reprogramar pedidos, calendario de entregas (bloquear / abrir fechas) y asignar pedido a
camión (`POST /app/orders/{n}/vehicle`). Alcance: todo el país, o su ciudad si tiene ciudad asignada (a
confirmar con el dueño; propuesta: por ciudad, igual que el preparador).
Que aparezca en `GET /app/staff?role=planificador`, en `StaffRoleName` (avisos por rol) y en el seeder de
usuarios de prueba (`planificador@dismac.test`).

¿El supervisor conserva `planning.write`? En la app el supervisor **solo mira** (decisión anterior); planifican
el planificador y el admin.

## 4. Menores

- `GET /app/shipments?city=`: hoy es texto libre contra la dirección. La app pasa a un **select de
  departamentos**: aceptar también el código (`la_paz`, `santa_cruz`…) filtrando por `destination_department`.
- Para mostrar en el envío entregado **cómo se entregó**, sumar a `Shipment` (lista y ficha):
  `delivery_evidence: { signature: bool, photo: bool, document: bool } | null`. Mientras tanto la app lo
  deduce de `GET /app/deliveries/{id}/evidence` al abrir el detalle (una llamada extra).

## Criterio de aceptación

Todo en `openapi/v1.yaml`. La app regenera el cliente y arma: detalle de plan sin UUID, asistente de viajes
(candidatos por cercanía + orden sugerido + ventanas horarias) y el rol planificador.
