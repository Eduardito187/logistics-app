# ETA viva por parada + detección de salida de ruta y recálculo

**Fecha:** 2026-11-16 · **Pedido por:** el dueño · **Estado:** derivado al backend (la app aporta la
ubicación; el cálculo de ruta y ETA es del backend, que ya tiene el motor de ruteo).

## Idea

La app ya manda la ubicación del camión. Con ese flujo, el backend:
1. detecta si el camión **se salió de la ruta** (comparando la posición contra el trazado del plan, que ya
   persiste en `plan.route_geometry`);
2. le arma una **ruta nueva hacia la siguiente parada** cuando se salió;
3. recalcula la **ETA** de cada parada restante (la velocidad y la distancia salen del mismo flujo de
   posiciones) y la empuja por los sockets que ya cableamos.

La app **no calcula ruta ni ETA de ruta**: solo aporta la posición, muestra lo que el backend empuja y
mantiene el último tramo cosmético desde su propio GPS ("Faltan X km · Y min" a la parada en curso).

## Lo que la app YA le da al backend

- `POST /tracking/.../position` (`ingestTruckPositionFromApp`), por lote, con id idempotente, offline-first:
  **`lat`, `lng`, `reported_at`** por posición. Con dos posiciones seguidas el backend ya puede derivar
  **velocidad** (Δdistancia/Δtiempo) y **rumbo**, y comparar contra la geometría para la **salida de ruta**.
- La ruta del día y su `route_geometry` ya están del lado del backend.

## 1. ETA planificada por parada, en TODAS las superficies (barato, ya se calcula)

Hoy la ETA completa por parada solo está en `GET /app/plans/{id}/eta`. Pedido: que **cada parada/envío
exponga su `eta_at`** desde el mismo motor, en las superficies que la app ya lee:

- paradas de la ruta del chofer (`GET /app/vehicles/{id}/route` → `stops[].eta_at`),
- "Consultar pedido" (`GET /app/orders/lookup` → `tracking.eta_at`, ya existe parcialmente),
- detalle de envío del admin,
- la **ventana prometida al cliente** debe salir de este mismo número (una sola verdad).

## 2. ETA viva: recalcular y empujar

Recalcular la cadena de ETAs de las paradas restantes cuando:
- se **completa/falla** una parada (se corren las siguientes), y
- el camión **se mueve de forma significativa** o cruza una geocerca (limitar a ~1 cada 15–30 s).

Empujar el resultado por socket. Dos opciones, la que te sea más limpia:
- un evento nuevo `eta.updated { route_id, vehicle_id, stops: [{ shipment_id, eta_at }] }`, o
- incluir `eta_at` por parada en el `route.updated` que ya definimos (el chofer ya se re-pide la ruta con
  ese evento; si trae las ETAs frescas, alcanza).

## 3. Salida de ruta y re-ruteo

- Marcar un estado **fuera de ruta** del camión cuando la posición se aleja del trazado más que un umbral
  (vos definís el umbral y la histéresis para no titilar).
- Al salirse, **recalcular la ruta hacia la siguiente parada** (re-ruteo puntual, no hace falta re-optimizar
  todo el plan) y actualizar `route_geometry` + las ETAs.
- Avisarlo a la app en el mismo evento: `route.updated { ..., off_route: bool, rerouted: bool }` (o un
  `tracking.updated` con ese estado). La app muestra "Fuera de ruta / recalculando" y, al llegar la ruta
  nueva, la pinta y refresca las ETAs. El chofer YA tiene un cartel "Fuera de ruta" en la pantalla de
  entrega; hoy lo decide local — mejor que lo mande el backend para que sea la misma verdad que ve el
  supervisor.

## 4. Opcional: enriquecer el envío de posición

Si para la detección de salida de ruta o la ETA te sirve más que `lat/lng/reported_at`, puedo sumar al
`TruckPositionInput` **`speed_mps`, `heading_deg` y `accuracy_m`** (el GPS del teléfono ya los tiene; hoy la
app los descarta). Decime si los querés y los agrego en cuanto estén en el schema; si con derivarlos de las
posiciones te alcanza, lo dejamos como está.

## Criterio de aceptación

- `eta_at` por parada consistente en plan, ruta del chofer, lookup y detalle de envío (un solo motor).
- La ETA se mueve sola (sin que el usuario refresque) al completar una parada y al avanzar el camión.
- Un camión fuera de ruta se ve como tal en la app y en el tablero del supervisor, con la ETA recalculada.
- Nada de esto lo calcula el teléfono: la app solo manda posición y muestra lo que el backend empuja.
