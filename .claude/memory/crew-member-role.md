---
name: crew-member-role
description: "nov 2026 — rol TRIPULANTE (ayudante del camión), login de solo lectura: avisos/perfil, consultar/escanear etiqueta, y ver los envíos del camión en el que participa (programados/en curso)"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-16T19:02:58.370Z
---

Decisión del dueño (2026-11-16): crear el rol **tripulante** (ayudante que va en el camión con el
chofer). Rol de LOGIN de **SOLO LECTURA**. Accesos: (1) avisos/notificaciones + perfil; (2) escanear
etiqueta / consultar pedido (ya abierto a todos vía `/app/orders/lookup`); (3) ver los envíos del camión
en el que participa, **programados o en curso**. NO carga, NO entrega, NO asigna (eso es del chofer).

**App HECHA (dormida hasta que el backend agregue el rol → sin regresión):**
- `UserRole.crewMember` con `backendKey: 'tripulante'` (`lib/core/auth/user_role.dart`). Mapea login y
  `/app/auth/me`; sin el rol en el backend nadie se loguea así.
- Feature `lib/features/crew/`: `CrewShipmentsScreen` ("Mis envíos"), solo lectura. Cabecera
  `AssignmentHeader` (camión/cuadrilla) + selector de fecha (hoy = en curso; otra fecha = programados) +
  lista de paradas (pedido, cliente, dirección, productos, estado) tappable → `/lookup`. Botón escanear
  → `/lookup`. `crew_routes.dart`: tarea `crew-shipments` (accent) + ruta `/crew/shipments`.
- **Reutiliza los MISMOS providers de lectura del chofer** (no suma llamadas): `myCrewProvider`,
  `assignedVehicleIdProvider`, `driverRouteProvider`, `selectedDateProvider` de `driver_controllers.dart`
  → `GET /app/fleet/my-crew?date=` + `GET /app/vehicles/{id}/route?date=`. 404 de my-crew = "no estás
  asignado a un camión" (vacío amable, no error rojo).
- Cableado: `feature_tasks.dart` (+crewTasks), `app_router.dart` (+crewRoutes), `home_shell.dart`
  (`_centerScreenFor` → CrewShipmentsScreen), `home_prefetch.dart` (prefetchDriverDay), y el rol sumado a
  `lookupTasks` y `settingsTasks`. `role_home_widgets`/`role_shortcuts` no rompen (mapas con default
  vacío). Test: `test/features/crew/presentation/crew_shipments_screen_test.dart` (reusa el soporte del
  chofer + testOnScreens). getDiagnostics 0/0.

**Falta del BACKEND** (`docs/backend-requests/2026-11-16-rol-tripulante-login-y-alcance.md`, enviado a
logistics-e8): (1) `Role::Tripulante='tripulante'` con abilities SOLO lectura + seed + asignable en
admin; (2) `my-crew` resuelto por **ayudante** (hoy solo por chofer); (3) confirmar que el ayudante pasa
el GET de `vehicles/{id}/route` por `EnsureVehicleCrew`; (4) `my-crew?date=<futuro>` para programados;
(5) usuario `tripulante@dismac.test`. Sin cambios de shape → **no requiere regen** del cliente.

Ver [[crew-contract-and-route-visibility]], [[business-rules-city-scope-lookup]],
[[feedback-no-over-derivar-backend]], [[admin-role-in-app]].
