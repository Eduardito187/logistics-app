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
