---
name: app-api-coverage-state
description: Estado al 2026-10-15 — la app consume 168/169 endpoints /app/* del backend; estructura por features con contrato de rutas/tareas.
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-15T06:42:14.121Z
---

Al **2026-10-15** la rama `feature/initial-scaffold` tiene la app Flutter completa consumiendo **168/169** endpoints `/app/*` (único sin consumir: `verifyLabel`, intencional, ver [[app-scope-backend-consumer]]). `flutter analyze` sin issues, 71 tests verdes. Sin commit/push aún.

**~20 features** en `lib/features/<f>/` (data/domain/presentation). Terreno: auth, picking, driver, store, carrier, supervisor, shipments, sync, notifications, settings. Oficina/ops (rol admin+supervisor): fleet, maintenance, fleet_costs, telemetry, network_config. Admin: messaging, outbox, sap, access (RBAC).

**Contrato de integración:** cada feature expone en `presentation/<f>_routes.dart` → `const List<RoleTask> <f>Tasks` y `final List<RouteBase> <f>Routes`. El coordinador los agrega en `lib/core/navigation/feature_tasks.dart` (home por rol) y `lib/core/router/app_router.dart`. Los agentes de feature NO tocan esos dos archivos ni pubspec/app.dart/main.dart.

**Roles:** `UserRole` (lib/core/auth/user_role.dart) con `backendKey` mapea a los roles del backend `App\Enums\Role`: chofer→driver, preparador→picker, tienda→store, transportista→carrier, supervisor→supervisor, **admin→admin** (rol de oficina, agregado para las vistas admin). `firstOperational(roles)` elige el rol de la sesión en el login real. Ver [[parallel-agents-method]] y [[api-client-generation]].
