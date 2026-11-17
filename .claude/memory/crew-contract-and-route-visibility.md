---
name: crew-contract-and-route-visibility
description: "nov 2026 — contrato de tripulaciones (crew por camión+día) y auto-crew al publicar que hace visible la ruta del chofer; quién puede asignar; estado del lado app"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-16T16:03:59.599Z
---

Contrato que mandó el backend (logistics-e8) el 16-nov-2026, **aplica tras el próximo deploy a staging**:

**Modelo de tripulación (crew) — por CAMIÓN y por DÍA:** crew = chofer + ayudantes + camión + fecha
(`assembled_for`). Reglas duras: un camión = UNA crew/día, un chofer = UN camión/día. Armar para un chofer
que ya tiene camión ese día REEMPLAZA atómico (la anterior va al historial). Si el camión destino ya lo
tiene OTRO chofer → **409** (con placa+nombre, nunca UUID) salvo `replace: true`. Repetir la misma
asignación es idempotente.

**Quién puede asignar (NUEVO, antes abierto):** SOLO `planificador`, `chofer`, `admin`, `supervisor`. El
resto (preparador, tienda, transportista) → **403** en las escrituras. La UI de asignar/editar/borrar crew
se muestra solo a esos roles.

**Endpoints (shape sin cambios):** POST/PUT/DELETE `/app/fleet/crews[/{id}]` (cuerpo
`{driver_id, helper_ids?, vehicle_id, assembled_for, shift_starts_at?, shift_ends_at?, replace?}`),
GET `/app/fleet/crews` (lectura abierta, paginada), GET `/app/fleet/my-crew` (el chofer: su camión y crew
del día).

**AUTO-CREW AL PUBLICAR (resuelve "al chofer no le sale la ruta", #4):** al publicar un plan, si el camión
del plan NO tiene crew ese día, el backend ARRASTRA el chofer más reciente de ese camión y arma la crew del
día → la ruta queda visible sin paso manual. Respeta un-chofer-un-camión; no roba a otro camión ni inventa
chofer si el camión nunca tuvo. **La ruta del chofer SIGUE dependiendo de que exista crew de ESE camión+día**:
si el camión nunca tuvo chofer, hay que armar la crew a mano (planner/chofer/admin).

**Estado del lado app (16-nov-2026):**
- Shape de my-crew YA está del regen anterior (`my_crew.dart`: vehicle, driver, helpers, shift). NO hace
  falta regenerar por este contrato (shape sin cambios).
- UI de asignar/quitar crew HOY = solo ficha de personal del admin (`admin_staff_profile_screen.dart`):
  admin ∈ set permitido, ya maneja el 409 (diálogo "ese camión ya tiene chofer → asignar igual" → `replace:
  true`) y 403/otros caen en showErrorSnack. No rompe con la restricción nueva.
- Exponer el armado de crew a planner/chofer/supervisor = **pantalla nueva aún no construida**; al hacerla,
  agregar `canAssembleCrew = {planner, driver, admin, supervisor}` en [[planner-role-and-planning]] y manejo
  explícito de 403.
- El chofer ya consume my-crew (`driver_vehicle_gate` → `myCrewProvider` → `AssignmentHeader`).
- **Sockets al publicar (confirmado por el backend):** `picking.updated` refresca la worklist del preparador;
  `route.updated` (en private-user.{id}) refresca la ruta del chofer. El auto-crew corre ANTES de armar la
  ruta, así que al salir `route.updated` la tripulación ya existe y le llega al chofer correcto.
- **FIX app (16-nov-2026):** `myCrewProvider` NO escuchaba ningún socket → la tripulación recién creada por
  el auto-crew no se recargaba, `assignedVehicleIdProvider` seguía null y el chofer quedaba en "sin vehículo"
  hasta reabrir (la ruta ni cargaba). Cableado: `myCrewProvider` ahora hace
  `ref.refreshOnRealtime(RealtimeTopic.user, {'route.updated'})` → el gate entra solo al publicar.
  `driverRouteProvider` ya escuchaba `route.updated`; `vehicleDeliveriesProvider`, `loading.updated`.
- **Borde manual CERRADO (backend, 16-nov-2026):** reasignar la tripulación a mano con la ruta ya existente
  (`fleet.crew_assembled` y ahora también `fleet.crew_vehicle_changed`) dispara `route.updated` en
  **private-user.{userId}** del chofer afectado (lo resuelve `RouteSignalReader` por `fleet_crews` del
  camión+día). Con el wiring actual (myCrew se recarga con cualquier `route.updated`, SIN filtro de vehículo)
  queda 100% en vivo: auto-crew al publicar y reasignación manual recargan myCrew + ruta solas, sin reabrir.
  Payload de `route.updated`: `{route_id: string|null, vehicle_id: string}` (en reasignación sin re-armar
  ruta, `route_id` puede venir null y `vehicle_id` es el camión NUEVO). OJO: el filtro por `vehicle_id` de
  `driverRouteProvider` descartaría el evento del camión nuevo, pero igual se reconstruye porque myCrew
  (sin filtro) cambia `assignedVehicleIdProvider` y driverRoute lo observa. NO tocar ese wiring. Sin cambios
  de openapi (eventos por nombre/payload).

Ver [[crew-duplicate-and-route-extra-stops]], [[business-rules-city-scope-lookup]], [[realtime-sockets-contract]],
[[pendientes-2026-11-15]].
