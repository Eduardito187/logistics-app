---
name: admin-role-in-app
description: nov 2026 — el dueño quiere el rol ADMIN completo en la app (antes era solo web); fase 1 hecha (entra con pantallas del supervisor); el resto depende de backend + regenerar el cliente
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-15T00:29:54.129Z
---

**Decisión del dueño (2026-11-14):** el admin SÍ entra a la app de campo (antes: "admin solo web/Filament").
Quiere: ver y buscar envíos, rutas, camiones y personal con documentos; fechas de envío y bloqueadas;
asignar personal a tiendas; asignar vehículo a chofer desde la ficha del personal; asignar viajes a
choferes/tripulaciones; mandar camión a mantenimiento; notificaciones por rol o a un usuario; reprogramar
pedidos (uno / por camión / por ciudad); flota en vivo nacional. **La ficha del personal es UNA sola
vista para todos los roles, contenido según el rol, por tabs y paginada** (documentos, fotos, historiales).

**Hecho (fase 1, sin compilar por mí):** `UserRole.admin` (backendKey `admin`); `firstOperational`
devuelve admin si el usuario lo tiene (aunque tenga otro rol); admin reutiliza las pantallas del
supervisor (`supervisor_routes` roles = {supervisor, admin}; centro = tablero; prefetch, accesos directos y
widget del inicio iguales). `UserRole.seesOperations`. Tests de roles actualizados.

**Bloqueos:**
1. El cliente generado está ATRASADO respecto del spec (p. ej. `listUsers` solo tiene `status`; el spec
   ya tiene `role`, `search`, `page`). Hay que **regenerar** (lo corre el dueño) antes de armar listas.
2. No existen en el API: ficha del personal (documentos/actividad/fotos), asignar personal a tienda,
   calendario de fechas bloqueadas, reprogramar pedidos, enviar notificaciones manuales, búsquedas en
   vehículos/choferes/planes. Pedido con contratos: `docs/backend-requests/2026-11-14-admin-en-la-app.md`
   (enviado a logistics-53).

**Ya existe en el cliente y sirve:** `/app/access/users*`, `/app/fleet/{vehicles,drivers,helpers,crews,
documents}`, `PATCH /app/fleet/vehicles/{id}/status`, `/app/fleetops/maintenance/*`, `/app/plans*`,
`/app/telemetry/fleet/live`.

**Tanda 1 del backend (2026-11-14, working tree sin commit; el dueño aprobó TODO el pedido):** `q`/`node_id`/
paginación en `/app/fleet/vehicles`; `q` + paginación en `/app/fleet/drivers`; `city`/`vehicle_id`/
`delivery_date` en `/app/shipments`; `base_node_id`/`base_node_name`/`city` en `/app/telemetry/fleet/live`;
tripulaciones `GET /app/fleet/crews?date=&vehicle_id=&driver_id=` (paginado), `PUT`/`DELETE
/app/fleet/crews/{id}` ("asignar camión a chofer" = POST crews por fecha); `POST
/app/fleet/vehicles/{id}/send-to-maintenance` (abre orden + estado; devuelve `open_route` con
`stops_remaining`; NO reasigna la ruta). Pendiente del backend: flujo recomendado para armar viajes, ficha
del personal + asignar a tienda (A+B), reprogramar + calendario (D+C), notificaciones (E).

**App módulo admin (hecho, sin compilar por mí):** `lib/features/admin/` con `AdminRemoteDataSource` (Dio
crudo, se migra al cliente al regenerar), `PagedSearchList<T>` (buscador con pausa + páginas + refrescar;
base para Personal), **Camiones** (`/admin/vehicles`: placa, estado, "No apto", mandar a mantenimiento con
aviso de paradas pendientes) y **Envíos** (`/admin/shipments`: q + ciudad + estado, detalle en hoja).
Registrado en `feature_tasks.dart` y `app_router.dart`. **Falta en la app:** filtro por ciudad en la flota
en vivo, tripulaciones, y los módulos que esperan al backend.

**Estado al cierre del 2026-11-14 (app completa contra el backend sin deploy):** el backend entregó TODO
(A–E + F + confirmaciones) en su working tree; el cliente se regeneró ([[api-client-generation]]) y
`AdminRemoteDataSource` usa el cliente generado. Pantallas (`lib/features/admin/presentation/`):
- **Personal** `/admin/staff` + ficha `/admin/staff/:userId` con 4 pestañas (Datos, Documentos, Actividad,
  Fotos; cada una paginada y cargada al abrirla). Datos cambia por rol: tienda asignada (asignar/cambiar),
  y si es chofer licencia + camión (asignar/cambiar/quitar = tripulación de HOY). Subir documento = foto.
  `userId` es ENTERO (tabla de usuarios de la app; `/app/access/users` es otro módulo, no usarlo).
- **Envíos** (q + ciudad + estado) con detalle: "Asignar a un camión" (`POST /app/orders/{n}/vehicle`, el
  camino recomendado por el backend para armar viajes) y "Reprogramar".
- **Reprogramar** `/admin/reschedule`: un pedido, un camión o una ciudad (+ acotar a un día); SIEMPRE vista
  previa antes de confirmar.
- **Calendario** `/admin/calendar`: 30 días, bloquear (motivo obligatorio) / desbloquear.
- **Avisos** `/admin/broadcasts`: por rol, tienda o persona (desde la ficha) + enviados con leídos.
  Bandeja para TODOS los roles: `/inbox` (`features/notifications`), acceso desde la campana.
- **Camiones** (mantenimiento) y **Flota en vivo** con filtro por ciudad y encuadre de toda la flota.
- `PagedSearchList<T>` y `Paged` viven en `lib/core/widgets/`.
**Pendiente:** QR de retiro (idea futura). Lo demás que figuraba pendiente acá (abrir fechas, datos
personales de cualquier rol, varias rutas por camión y día, "publicar plan") ya lo resolvió el backend: ver
las tandas de abajo.

**Tanda final del backend (2026-11-14, regenerado):** `send-to-maintenance` devuelve `route`
{reassigned[], pending_reassignment[]} y acepta `reassign_to_vehicle_id` (la hoja ofrece "Pasarlos a otro
camión"); bandeja única `/app/inbox` con `kind` notice|alert|document + `severity` y `meta.unread`
(alert/document no se marcan leídos); `PUT /app/staff/{id}/profile` y `POST .../photo` para CUALQUIER rol
(ficha: "Editar datos personales" y tocar la foto); varias rutas por camión y día. `StaffMember`/
`StaffProfile` tienen campos `required` aunque nullables: en tests usar constructores de ayuda.

**Tanda de limpieza de contrato (2026-11-14, regenerado y adaptado):** nombres estables en el cliente
(`DeliveryMode`, `CrewDriver`/`CrewVehicle`, `StaffDriverData`, `StaffRoleName`, `AcceptedEnvelopeData`;
`status` de envíos va como lista). Calendario: **"Abrir fechas"** ya existe (`openDays(from, to)` →
`capacity.openDeliverySlotsWithDefaults`, el backend pone los cupos por defecto de sus reglas; ya no hacen
falta catálogos). Despacho: el pedido queda autorizado si tiene camión asignado; `authorized_reason_code`
decide el texto (`dispatchBlockText`, pastilla "Falta asignar camión") — ya no depende de "publicar plan".

**How to apply:** módulos nuevos en `lib/features/admin/<modulo>/` (personal, envíos, camiones,
calendario, reprogramar, avisos). Armar cada uno cuando el backend confirme su contrato y el cliente esté
regenerado; no escribir DTOs a mano para volumen (regla 5). Ver [[feedback-working-style]],
[[app-api-coverage-state]].
