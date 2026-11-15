# Rol ADMIN en la app: qué existe y qué falta en el API

- **De:** app interna DisTrack (logistics-app)
- **Para:** backend logistics
- **Fecha:** 2026-11-14
- **Prioridad:** Alta (pedido del dueño: "completo y bien implementado").

## Pedido del dueño

El **admin** entra a la app y puede: ver y buscar **envíos**, **rutas**, **camiones** y **personal con sus
documentos**; agregar **fechas de envío** y **fechas bloqueadas**; **asignar personal a tiendas**; **asignar
vehículos a choferes** desde la ficha del personal; **asignar viajes** a choferes y tripulaciones; revisar
camiones y **mandarlos a mantenimiento**; **enviar notificaciones** por rol (todos los choferes) o a un
usuario; **reprogramar** pedidos (uno, todos los de un camión, todos los de una ciudad); y ver la **flota en
tiempo real a nivel nacional**. La ficha del personal es **una sola vista** para todos los roles, con el
contenido según el rol de la persona, en **tabs y paginada** (documentos, fotos, historiales).

## Qué hizo ya la app

- Rol `admin` habilitado (`UserRole.admin`): entra con las pantallas del supervisor (tablero, flota en
  vivo, rutas en curso, alertas). Un usuario con `admin` + otro rol entra como admin.
- El resto espera (a) lo de abajo y (b) **regenerar el cliente**: el cliente de la app está atrasado
  respecto del spec (p. ej. `GET /app/access/users` en el cliente solo tiene `status`; el spec ya tiene
  `role`, `search`, `page`).

## Necesito confirmar (existe en el spec, ¿sirve tal cual para admin?)

1. **Login de admin en `/app/auth/login`** con todas las abilities de lectura/escritura de abajo. ¿`admin`
   pasa todos los middlewares de `/app/*` (flota en vivo, planes, alertas, fleet, fleetops, access)?
2. **Flota nacional:** `GET /app/telemetry/fleet/live` ¿devuelve TODOS los vehículos del país para admin (sin
   acotar por nodo/ciudad)? ¿Trae ciudad/nodo base por vehículo para filtrar y agrupar?
3. **Asignar vehículo a chofer / tripulación:** `POST /app/fleet/crews` (por fecha). ¿Es el camino correcto
   para "asignar un camión a un chofer"? Falta un `GET /app/fleet/crews?date=&vehicle_id=&driver_id=` para
   ver la tripulación vigente, y poder **cambiarla/quitarla**.
4. **Asignar viajes:** `POST /app/plans` + `/stops` + `/publish` y `POST /app/orders/{n}/vehicle`. ¿Cuál es
   el flujo recomendado para que el admin arme el viaje de un camión con N pedidos desde el teléfono?
5. **Mantenimiento:** `PATCH /app/fleet/vehicles/{id}/status` + `POST /app/fleetops/maintenance/orders`.
   ¿"Mandar a mantenimiento ahora" es crear la orden y cambiar el estado, o una sola llamada lo hace? ¿Qué
   pasa con la ruta del día de ese camión?

## Qué falta (no está en el spec)

### A. Ficha del personal (una vista, tabs por rol)
`GET /app/access/users/{id}` hoy devuelve id, nombre, email, estado, roles, último login. Falta un perfil
operativo:

```yaml
# GET /app/staff/{userId}   (o enriquecer /app/access/users/{id})
data:
  user: { id, name, email, phone, document_id, photo_url, status, role_keys, last_login_at }
  node: { id, code, name } | null            # tienda / CD asignado
  driver: { id, license_number, license_category, license_expires_at } | null
  current_vehicle: { id, plate, vehicle_class } | null   # asignación vigente (chofer/ayudante)
  devices: [{ uuid, platform, name, last_seen_at, revoked_at }]
```

Y, paginados (`page`/`per_page` + `meta`), por separado para cargar cada tab bajo demanda:

- `GET /app/staff/{userId}/documents` — carnet, licencia, contrato, etc.: `{id, kind, number, issued_at,
  expires_at, status, file_url}` (URL firmada como la evidencia).
- `POST /app/staff/{userId}/documents` (multipart) — subir/reemplazar un documento o la foto.
- `GET /app/staff/{userId}/activity` — historial según el rol: chofer (rutas, entregas, fallidas,
  checklists, incidentes), preparador (pedidos preparados/etiquetados), tienda (recepciones, recojos
  entregados), transportista (viajes). Un feed `{id, type, title, occurred_at, reference, link_id}` con
  filtro `type` y rango de fechas.
- `GET /app/staff/{userId}/photos` — evidencia subida por esa persona (POD, daños), paginada.

### B. Asignar personal a tiendas
`PUT /app/staff/{userId}/node` `{ node_id | null }` (y que `GET /app/access/users` acepte `node_id` como
filtro y devuelva `node` en cada usuario). Hoy la tienda del usuario llega en el login pero no hay cómo
cambiarla desde `/app`.

### C. Fechas de envío y fechas bloqueadas
`GET /app/capacity/calendar` es solo lectura. Falta gestionar:

```yaml
GET    /app/delivery-calendar?from=&to=&node_id=&city=
       # días con: open | blocked, motivo, cupo y usados
POST   /app/delivery-calendar/blocked   { date | {from,to}, scope: {city? node_id?}, reason }
DELETE /app/delivery-calendar/blocked/{id}
POST   /app/delivery-calendar/open      { date, scope, capacity? }   # habilitar una fecha de envío extra
```

### D. Reprogramar pedidos (uno, por camión, por ciudad)
No hay endpoint (hoy solo reprograma el backend ante un incidente).

```yaml
POST /app/shipments/reschedule
  { scope: { shipment_ids?: [uuid], vehicle_id?: uuid, city?: string, route_date?: date },
    new_date: date, window_start?: "HH:MM", window_end?: "HH:MM",
    reason: string, notify_customer: boolean }
  # 200: { rescheduled: n, skipped: [{shipment_id, reason}] }  (entregados/anulados no se tocan)
POST /app/shipments/reschedule/preview    # mismo body → cuántos y cuáles, sin aplicar
```

Con `preview` la app muestra "vas a reprogramar 37 pedidos" antes de confirmar. Debe respetar las fechas
bloqueadas de C y dejar auditoría (quién, cuándo, motivo).

### E. Notificaciones a usuarios internos
`/app/notifications*` es bandeja y plantillas; no hay envío manual.

```yaml
POST /app/notifications/send
  { audience: { role?: chofer|preparador|tienda|transportista|supervisor, user_ids?: [id], node_id?: uuid },
    title: string(≤80), body: string(≤500), link?: string }
  # 202: { recipients: n }   → push (FCM) + bandeja de la app
GET  /app/notifications/sent?page=    # historial de lo enviado por admins
```

### F. Búsqueda en listas (para el buscador del admin)
- `GET /app/shipments?q=` (ya lo hiciste) + filtros `city`, `delivery_date`, `vehicle_id`.
- `GET /app/fleet/vehicles?q=&status=&node_id=&page=` y `GET /app/fleet/drivers?q=&page=`.
- `GET /app/plans?date=&vehicle_id=&status=&page=` (rutas de envíos).

## Orden sugerido

1. Confirmaciones 1–5 + F (permite listas/buscadores y flota nacional ya).
2. A + B (ficha del personal).
3. D + C (reprogramar y calendario).
4. E (notificaciones).

Todo en `openapi/v1.yaml`; la app regenera el cliente y arma cada módulo en `lib/features/admin/`.
