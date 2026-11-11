---
name: app-api-coverage-state
description: Estado al 2026-10-15 — la app consume 168/169 endpoints /app/* del backend; estructura por features con contrato de rutas/tareas.
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-05T05:45:23.546Z
---

Al **2026-10-15** la rama `feature/initial-scaffold` tiene la app Flutter completa consumiendo **168/169** endpoints `/app/*` (único sin consumir: `verifyLabel`, intencional, ver [[app-scope-backend-consumer]]). `flutter analyze` sin issues, 71 tests verdes. Sin commit/push aún.

**~20 features** en `lib/features/<f>/` (data/domain/presentation). Terreno: auth, picking, driver, store, carrier, supervisor, shipments, sync, notifications, settings. Oficina/ops (rol admin+supervisor): fleet, maintenance, fleet_costs, telemetry, network_config. Admin: messaging, outbox, sap, access (RBAC).

**Contrato de integración:** cada feature expone en `presentation/<f>_routes.dart` → `const List<RoleTask> <f>Tasks` y `final List<RouteBase> <f>Routes`. El coordinador los agrega en `lib/core/navigation/feature_tasks.dart` (home por rol) y `lib/core/router/app_router.dart`. Los agentes de feature NO tocan esos dos archivos ni pubspec/app.dart/main.dart.

**Roles:** `UserRole` (lib/core/auth/user_role.dart) con `backendKey` mapea a los roles del backend `App\Enums\Role`: chofer→driver, preparador→picker, tienda→store, transportista→carrier, supervisor→supervisor, **admin→admin** (rol de oficina, agregado para las vistas admin). `firstOperational(roles)` elige el rol de la sesión en el login real. Ver [[parallel-agents-method]] y [[api-client-generation]].

**2026-11-05 — backend cerró los 4 pedidos de la vista chofer** (doc `docs/backend-requests/2026-11-05-chofer-fecha-ids-costos.md`, verificados por la sesión backend logistics-8e): (1) `route_date` acepta ISO y Y-m-d; (2) `POST /app/vehicles/{id}/route` → `stops` ahora OPCIONAL, ensambla desde el plan publicado (era el 422 "The stop field is required" que dejaba "Mi ruta" vacía); (3) `GET /app/vehicles/{id}/deliveries` ahora trae `reference` (required, no-UUID) + `order_reference`/`customer_name`/`address`; (4) `cost-summary` con datos reales sembrados (FleetOpsCostScenarioSeeder, vehículo 904U10 / chofer@dismac.test). **PENDIENTE de la app:** regenerar el cliente Dart desde `openapi/v1.yaml`, consumir `reference` en la lista de "Mi ruta" y dejar de mandar `stops: []` (hoy `driver_route_repository_impl.dart` manda lista vacía). Ver [[api-client-generation]] y [[test-pass-detected-flaws]].
