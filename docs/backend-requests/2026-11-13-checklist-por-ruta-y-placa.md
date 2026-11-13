# Checklist pre-salida ligado a la ruta/viaje + placa en el historial

**Fecha:** 2026-11-13 · **Pide:** app interna (chofer) · **Para:** backend `logistics`
**Prioridad:** media.

Pedido del dueño: la inspección pre-salida (checklist) debe ir **por viaje/ruta**, no por día:
"si sale a 2 entregas, revisa 2 veces". Hoy el checklist es **diario** (la app solo sabe si hubo
una inspección hoy). Para hacerlo por ruta y mostrar bien el historial, falta soporte del backend.

## 1. Asociar el checklist a la ruta/viaje

Hoy `POST /app/.../pre-trip-checklists` (`ConductPreTripChecklistRequest`) lleva
`vehicle_id`, `driver_id`, `items`, `performed_on`, `notes` — **sin ruta**. Y `PreTripChecklist`
no trae `route_id`.

**Pedido:**
- Aceptar un `route_id` (o `trip_id`) OPCIONAL en el request del checklist, para ligar la
  inspección a la ruta del día que se va a hacer.
- Devolver ese `route_id` en `PreTripChecklist`.

## 2. Saber si la RUTA actual ya tiene checklist (para el gate y el "al día")

Para que la app muestre el recordatorio/el estado **por ruta** (no por día) necesita saber si la
ruta en curso ya tiene su inspección. Preferido:
- un campo en el read-model de la ruta (`DriverRoute`), p. ej. `pre_trip_checklist_done: bool`
  (y opcional `pre_trip_checklist_id`), que sea `true` cuando existe un checklist ligado a ESA
  ruta; **o**
- permitir filtrar `GET /app/.../pre-trip-checklists?route_id=…` (o incluir el `route_id` en cada
  item para que la app filtre).

Con esto, la app:
- muestra el formulario / recordatorio AMARILLO cuando la ruta actual **no** tiene checklist;
- muestra el estado verde **"Camión al día"** cuando la ruta actual **sí** lo tiene;
- en una segunda ruta del día, vuelve a pedir el checklist (hoy lo resolvemos con un botón
  "Rehacer inspección", provisional — ver "Lado app").

## 3. Placa (y chofer) en el historial de inspecciones

`PreTripChecklist` trae `vehicle_id` pero **no la placa**. El historial debería mostrar, por
inspección, la **placa** del camión que se revisó (por si el chofer cambió de camión entre días).

**Pedido:** agregar a `PreTripChecklist`:
- `plate` (string) — la placa del `vehicle_id` de esa inspección;
- opcional `driver_name` (string) — quién firmó.

La fecha y la **hora** ya las tenemos (`performed_on` es datetime; la app ya muestra `HH:mm`).

## Lado app (ya hecho en esta sesión)

- **Hora de entrega en las paradas:** cada parada resuelta muestra "Entregada HH:mm" / "Fallida
  HH:mm" (de `settled_at`); las pendientes siguen con ETA.
- **Estado "al día" del checklist:** si la inspección de HOY ya está hecha, la pantalla muestra
  "Camión al día" (verde, estilo mantenimiento) con la hora y la placa, en vez del formulario; con
  botones "Rehacer inspección (otra salida)" y "Ver historial". Cuando el backend exponga el flag
  por ruta (punto 2), el "Rehacer" deja de ser manual y pasa a ser automático por ruta.
- **Historial con placa:** cada inspección muestra fecha + hora + la placa del camión asignado
  (cuando el backend mande `plate` por item, se usa esa, para casos de cambio de camión).

Al regenerar el cliente API tras estos cambios, la app consume `route_id`/`plate`/el flag sin
código nuevo (solo cablear el gate por ruta).
