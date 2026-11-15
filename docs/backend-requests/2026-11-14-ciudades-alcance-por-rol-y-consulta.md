# Ciudades (departamentos), almacén central, alcance por rol y consulta de pedidos

- **De:** app interna DisTrack (logistics-app)
- **Para:** backend logistics
- **Fecha:** 2026-11-14
- **Prioridad:** Alta. Reglas de negocio del dueño que cruzan todo el proyecto.

## Lo que pidió el dueño (textual, resumido)

1. Todo el personal (tienda, chofer, preparador, todos) debe estar **asignado a un departamento** (ciudad
   de Bolivia). Una ciudad puede tener un **almacén central**; **no todas** lo tienen. Todo esto tiene que
   coexistir y engranar con el resto del proyecto.
2. **Preparador:** un preparador de La Paz **no puede preparar** un pedido de Santa Cruz, pero **sí puede
   escanear su etiqueta** para ver la información.
3. **Tienda:** el personal de tienda solo ve lo que **sale o entra a SU tienda**, sin importar que salga
   hacia otra ciudad o llegue desde otra ciudad.
4. **Chofer:** como la tienda, pero solo los pedidos que **le asignaron a él**.
5. **Todos los usuarios** tienen el **escáner de QR** para ver información de **cualquier** pedido, tengan
   o no el rol para procesarlo.
6. **La tienda solo entrega al cliente final.** Que el pedido llegó a la tienda lo marca **el chofer** al
   dejarlo (escaneo + foto). El personal de tienda no recibe mercadería.
7. Si el **cliente va a la tienda** a preguntar por su pedido, el de tienda lo busca y le dice **si está en
   camino, en qué estado está y a cuántas paradas** de llegar.
8. El **chofer puede salir N veces al día**, con el mismo camión o con otro, según lo que le asignen. La
   **inspección del vehículo y el odómetro van ligados a cada SALIDA**: inspecciona (el mismo camión u
   otro) y registra odómetro cada vez que sale.

## Qué hizo ya la app

- **Consultar pedido** (`/lookup`) para **todos los roles**: escanear una etiqueta o escribir el código y
  ver cliente, destino, productos y **etapa** (recibido, planificado, preparado, en camino, en la tienda
  listo para retirar, entregado) con las fechas de cada hito. Usa `GET /app/shipments?q=` y, para Code128,
  `GET /app/labels/{id}/resolve`. Es solo lectura.
- **Tienda:** se quitó "Recepción de mercadería" del rol. Queda "Recojo en tienda" (entrega al cliente) y,
  si el pedido buscado no está listo, "Consultar estado del pedido".
- **Chofer:** "Entregar en tienda" con `store-drop`. Odómetro de salida y de llegada con `route_id`;
  inspección por `route_id`.

## Qué necesita la app del backend

### A. Ciudad en el usuario y en la red
- `city` (departamento) en cada usuario de la app: en el login (`/app/auth/login`, `/app/auth/me`) y en
  `/app/staff` (lista y ficha), editable con `PUT /app/staff/{userId}/profile` o un `PUT .../city`.
  Filtro `city` en `GET /app/staff`.
- Catálogo `GET /app/network/cities`: `[{ code, name, central_warehouse: { node_id, name } | null }]`, para
  elegir la ciudad de una persona y saber cuáles tienen almacén central.
- Regla de consistencia: si la persona tiene tienda/nodo asignado, su ciudad es la de ese nodo.

### B. Alcance por rol (lo aplica el servidor, no la app)
El filtro de datos NO puede depender de que la app mande un parámetro: tiene que salir del usuario.

| Rol | Qué LISTA y PROCESA | Qué puede CONSULTAR |
|---|---|---|
| Preparador | Pedidos que se preparan en SU ciudad (origen = almacén/CD de su ciudad) | Cualquier pedido, por etiqueta o código |
| Tienda | Pedidos que SALEN de su tienda o LLEGAN a su tienda, sea cual sea la otra ciudad | Cualquier pedido |
| Chofer | Solo los pedidos de las rutas que le asignaron | Cualquier pedido |
| Transportista | Los de sus viajes | Cualquier pedido |
| Supervisor / Admin | Todo (admin: todo el país) | Todo |

Concretamente:
- `GET /app/shipments` con `status=PLANNED|RECEIVED` (la lista "Pedidos por preparar") debe devolver, para
  un preparador, **solo los de su ciudad**. Hoy devuelve los de todo el país (el preparador de prueba ve
  La Paz, Cochabamba y Santa Cruz mezclados).
- Las **escrituras** de preparación (`/app/orders/{n}/labels`, `/vehicle`, escaneos de preparación) deben
  responder **403** con un `code` propio (p. ej. `out_of_scope_city`) si el pedido no es de su ciudad. La
  app muestra el motivo.
- Tienda: hoy solo filtra por nodo **destino**. Falta incluir lo que **sale** de la tienda (origen).

### C. Consulta abierta para todos los roles
`GET /app/shipments?q=` está sujeto al alcance del rol, así que un preparador de La Paz no encontraría un
pedido de Santa Cruz. Hace falta una consulta **solo de lectura y sin alcance**:

```yaml
GET /app/orders/lookup?q=<código de pedido | label_id>
# 200: lista corta (máx. 10) de pedidos, mismo shape de Shipment (con `progress`), más:
tracking:
  stage: received | planned | prepared | on_the_way | at_store | delivered | failed | cancelled
  stops_before: integer | null      # paradas que el camión tiene ANTES de esta (null si no está en ruta)
  eta_at: date-time | null
  vehicle_plate: string | null
  current_node: { id, name } | null # dónde está ahora (tienda/almacén), si aplica
can_process: boolean                 # si ESTE usuario puede operar el pedido (su ciudad / su tienda / su ruta)
```

`stops_before` es lo que la tienda le dice al cliente: "está a 3 paradas". `can_process` le deja a la app
mostrar "solo consulta" cuando el pedido no es del alcance del usuario.

`GET /app/labels/{labelId}/resolve` debe quedar **sin alcance** (cualquier rol resuelve cualquier
etiqueta), como hoy.

### D. Tienda sin recepción
Con el punto 6, la conciliación de la recepción por la tienda deja de ser un paso del personal. El respaldo
que dejaste (si la tienda concilia, se registra la entrega en tienda) ya no se va a disparar desde la app.
Confirmar que **nada del flujo depende** de que la tienda abra o concilie una recepción (cupos, estado del
envío, liquidaciones). Faltantes y sobrantes en la entrega del chofer: decinos dónde se registran ahora
(¿el chofer reporta lo que no pudo dejar?).

### E. N salidas por día
Ya resolviste varias rutas por camión y día. Falta confirmar para el **chofer**:
- un chofer puede tener en el día rutas con **camiones distintos** (una abierta a la vez);
- `GET /app/fleet/my-crew` devuelve la tripulación de la salida **vigente** (no la primera del día);
- `POST /app/fleetops/odometer` con `source=departure` y `route_id` acepta **una por ruta**, igual que la
  `arrival` (409 en la segunda);
- el bloqueo "camión no apto" por inspección crítica aplica a la salida en curso.

## Criterio de aceptación

1. Un preparador solo lista y prepara pedidos de su ciudad; intentar otro da 403 con motivo.
2. Cualquier rol escanea cualquier etiqueta y ve el estado del pedido, sin poder operarlo.
3. La tienda ve lo que entra y sale de su tienda, y puede decirle a un cliente a cuántas paradas está.
4. Cada persona tiene ciudad; las ciudades con almacén central se pueden listar.
5. Todo en `openapi/v1.yaml`.
