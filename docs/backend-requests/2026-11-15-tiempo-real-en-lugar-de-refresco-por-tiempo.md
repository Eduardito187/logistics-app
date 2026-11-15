# Tiempo real (sockets) en lugar de refresco por tiempo

**Fecha:** 2026-11-15 · **Pedido por:** el dueño ("todo lo que usa refresco cada cierto tiempo se migra a
sockets") · **Estado:** entregado por el backend (working tree, sin deploy) y consumido por la app.

## Cómo quedó (respuesta del backend)

- Canales reales: `private-fleet.all` / `private-fleet.city.<codigo>` y `private-planning.all` /
  `private-planning.city.<codigo>` (admin y supervisor `.all`; planificador, su ciudad). La app los toma de
  `channels`, no los arma.
- `notifications.updated {scope: feed|user}`, llega ~3 s después del cambio.
- `fleet.position`: máx. 1 por camión cada 5 s, con emisión final al cerrar la ventana (la app NO refresca
  por tiempo con socket). `fleet.removed {vehicle_id}` = camión dado de baja; se quita por id.
- `planning.run.updated {plan_date, strategy, status, run}`; `plans.updated {plan_date, plan_id|null}`; pueden
  llegar varios seguidos → la app los junta 400 ms. `plans.updated` trae
  `deleted: bool`; con `true` la app cierra el detalle de ese plan sin volver a pedirlo.
- `DELETE /app/plans/{planId}` (204; 409 si está publicado): botón "Eliminar plan" en el detalle de un plan
  sin publicar.

Lo de abajo es el pedido original.

## Qué refrescaba por tiempo en la app

| Pantalla | Antes | Ahora |
| --- | --- | --- |
| Notificaciones (avisos + notificaciones) | cada 20 s | evento en el canal del usuario |
| Flota en vivo | cada 30 s (90 s con ahorro de batería) | evento por posición, se aplica sin volver a pedir |
| Planificación del día (corrida automática) | cada 5 s mientras corre | evento por cambio de estado |
| Lista y detalle de planes | solo al entrar o tirar para refrescar | evento cuando otro teléfono cambia un plan |

El refresco por tiempo queda **solo como respaldo** cuando no hay socket (entorno con `enabled: false`,
conexión caída o un tema sin canales para ese usuario).

## 1. `GET /app/broadcasting/config`: agregar `channels`

Mapa **tema → canales** que ESE usuario puede escuchar. La app no arma nombres de canal ni sabe de ciudades
o permisos: el alcance lo decide el backend.

```json
{
  "enabled": true, "key": "…", "cluster": null, "path": "/app",
  "channels": {
    "user": ["private-user.42"],
    "fleet": ["private-fleet.SCZ"],
    "planning": ["private-planning.SCZ"]
  }
}
```

- Tema ausente o lista vacía = ese usuario no tiene tiempo real para esa pantalla (sigue el respaldo).
- Sin `channels`, la app usa solo `private-user.{id}` (compatible con lo desplegado hoy).
- `POST /app/broadcasting/auth` firma exactamente los canales listados (403 para el resto). Un 403 en un
  tema opcional no corta la conexión.
- El valor puede ser un string o una lista.

## 2. Tema `user`

- `inbox.updated {unread}` — ya existe.
- **Nuevo** `notifications.updated` (payload libre) cada vez que cambia lo que ese usuario ve en
  `GET /app/notifications`. La app lo usa como señal para volver a pedir la lista.

## 3. Tema `fleet` (Flota en vivo)

Mismo alcance que `GET /app/telemetry/fleet/live`.

- `fleet.position`: el **mismo objeto** que un elemento de esa lista (schema `VehicleLive`). Obligatorios:
  `vehicle_id`, `lat`, `lng`, `moving`, `recorded_at`. Si no vienen placa, chofer, sede o ciudad, la app
  conserva los que ya tenía. Una lectura con `recorded_at` más viejo que el mostrado se descarta. Si falta
  un obligatorio, la app vuelve a pedir la lista entera.
- Opcional `fleet.removed {vehicle_id}` cuando un camión deja de estar en vivo.
- Se puede limitar a un evento por camión cada ~5 s.

## 4. Tema `planning` (planes)

- `planning.run.updated {plan_date}` en cada cambio de estado de la corrida automática
  (`queued → processing → completed/failed`). La app vuelve a pedir `GET /app/plans/auto` y la lista.
- `plans.updated {plan_date, plan_id?}` cuando se crea, edita (paradas/orden), publica o borra un plan.
  La lista se refresca si `plan_date` es el día que se mira; el detalle, si `plan_id` es el suyo (o no viene).
- `plan_date` en `Y-m-d`.

## Del lado de la app

Una sola conexión (`lib/core/realtime/`): siempre escucha `user`; `fleet` y `planning` solo mientras su
pantalla está a la vista. En segundo plano se desconecta (lo urgente llega por push).
