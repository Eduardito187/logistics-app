---
name: realtime-sockets-contract
description: "nov 2026 — el dueño quiere SOCKETS, no refresco por tiempo; conexión única en lib/core/realtime (hub + bus por temas user/fleet/planning), contrato de canales/eventos pedido al backend, polling solo como respaldo sin socket"
metadata:
  type: project
---

**Decisión del dueño (2026-11-15):** todo lo que refrescaba cada cierto tiempo va por sockets. Una pantalla
nueva que necesite estar al día NO debe usar `Timer.periodic`: se anota a un tema de tiempo real.

**Cómo está armado (`lib/core/realtime/`):** `RealtimeHub` (una sola conexión Pusher, activa con sesión y app
en primer plano, se crea en `HomeShell`) + `RealtimeBus` (las pantallas hacen `bus.listen(tema, cb)` o usan
el widget `RealtimeListener`; no abre red, sirve en tests) + `realtimeTopicLiveProvider(tema)` (¿ese tema
llega por socket ahora?). El hub se suscribe a un tema solo mientras alguien lo escucha. El refresco por
tiempo quedó SOLO como respaldo cuando el tema no está en vivo (entorno sin sockets, conexión caída, tema sin
canales).

**Contrato pedido al backend** (doc `docs/backend-requests/2026-11-15-tiempo-real-en-lugar-de-refresco-por-tiempo.md`,
entregado por el backend el 2026-11-15 en working tree, sin deploy en staging): `GET /app/broadcasting/config` suma
`channels` (tema → canales del usuario; la app no arma nombres, salvo `private-user.{id}` de compatibilidad).
Eventos: `user` → `inbox.updated`, `notifications.updated`; `fleet` → `fleet.position` (objeto VehicleLive, se
aplica en `FleetLive.apply`), máx. 1 por camión cada 5 s con emisión final, sin refresco por tiempo con socket; `fleet.removed {vehicle_id}` quita el camión dado de baja; `planning` → `planning.run.updated`, `plans.updated`
(`plan_date` Y-m-d, `plan_id` o null, `deleted` → cierra el detalle; "Eliminar plan" = `DELETE /app/plans/{id}` por Dio directo, solo sin publicar; llegan en ráfaga → `RealtimeListener` los junta 400 ms). Canales reales `private-fleet.all|city.<cod>`, `private-planning.all|city.<cod>`: solo admin/supervisor/planificador.

**Migrado:** Notificaciones (20 s), Flota en vivo (30 s), corrida de planificación (5 s); además lista y
detalle de planes ahora se refrescan solos. Ver [[run-environments-config]], [[planner-role-and-planning]].

**Chofer (2026-11-15):** `driverRouteProvider` escucha `route.updated {route_id|null, vehicle_id}` en el canal
del usuario y se vuelve a pedir solo (ignora eventos de otro camión). El backend lo dejó ESCRITO pero sin
verificar ni desplegar: no darlo por disponible. Staging ya tiene contenedor de sockets, pero el resto del
contrato (channels, fleet, planning) sigue sin deploy; hasta entonces corre el refresco de respaldo.
Trampa de Riverpod: en `ref.onDispose` no se puede leer otro provider (por eso el hub guarda el bus en un
campo); y un notifier no debe tocar otro provider dentro de `build` ni de un `dispose` de widget (microtarea).

**Segunda tanda (2026-11-15, noche) — 5 temas más, app HECHA, backend en su "segunda ola" (sin emitir aún):**
`picking` (`picking.updated` {shipment_id, plan_id, vehicle_id; pedido `order_reference`}) → lista de pedidos
por preparar, etiquetas y productos del pedido; `store` (`store.updated` {node_id, shipment_id}) → bandeja de
la tienda y recepción; `tracking` (`tracking.updated` {shipment_id, order_reference, status, event}, para
TODOS los roles con su alcance) → "Consultar pedido" y Envíos del admin; `operations` (`alerts.updated`,
`dashboard.updated` {plan_date}) → alertas y tablero; `loading` (`loading.updated` {vehicle_id, shipment_id})
→ hoja de carga del chofer. Canales por dimensión (`<tema>.all|city.<dep>|node.<id>|driver.<id>|vehicle.<id>`),
siempre tomados de `channels`.
**Cómo sumar otra pantalla:** en su provider de lectura, `ref.refreshOnRealtime(tema, {eventos}, when: ...)`
(`lib/core/realtime/realtime_refresh.dart`, debounce 400 ms, `realtimeMatches` para filtrar por id); para
listas paginadas, `PagedSearchListState.refreshSilently()` con `RealtimeListener`. Son SEÑALES: se vuelve a
pedir el endpoint de siempre. No va por sockets: escaneos/entregas/fotos (cola offline) ni el envío de GPS.
Sin hacer: el detalle (hoja) de un envío del admin ya abierto no se actualiza en vivo.

**2ª ola + ETA/ruta: EN EL CLIENTE (regen del 2026-11-16, sin deploy).** Modelos de los 5 temas (PickingUpdatedEvent, StoreUpdatedEvent, LoadingUpdatedEvent, Alerts/DashboardUpdatedEvent, TrackingUpdatedEvent) ya existen, pero la app los consume por nombre+payload (no por modelo tipado), así que el regen no cambió el consumo: funcionan al desplegar. Cableado nuevo: `off_route`(bool?)/`off_route_since` en DriverRoute → cartel "Fuera de ruta" del chofer (respaldo local si null); `route.updated` opcionales `off_route?/rerouted?/stops?[].eta_at` (ya se re-pide la ruta al recibirlo → ETAs frescas); campos GPS en TruckPositionInput. El backend NO redibuja la polilínea OSRM al reruteo (solo ETA) — pedir si molesta. Ver [[api-client-generation]].
