---
name: checklist-por-ruta-y-hora-entrega
description: "nov 2026 — checklist pre-salida POR RUTA (no por día) con auto-upgrade sin regresión; hora de entrega en paradas; estado 'al día' + historial con placa; campos aditivos del cliente agregados a mano"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-13T17:39:10.030Z
---

**Pedidos del dueño (nov 2026):** mostrar la HORA DE ENTREGA en cada parada; que el
checklist de pre-salida (inspección) no muestre el formulario si ya se hizo y de un mensaje
de éxito "al día" (estilo mantenimiento); ligar el checklist a la RUTA/viaje para que "si
sale a 2 entregas revise 2 veces"; y en el historial de inspecciones ver fecha + hora +
PLACA del camión.

**Checklist POR RUTA (no por día).** Antes era diario (`inspectionDoneToday`). Ahora el
backend (logistics-42, working tree, requiere `php artisan migrate` de la columna `route_id`)
agregó: `route_id` opcional en `ConductPreTripChecklistRequest` + `GET
.../pre-trip-checklists?route_id=`; y `route_id`/`plate`/`driver_name` (nullable) en
`PreTripChecklist`. Decisión de diseño del backend: NO hay flag en `DriverRoute` (evita
acoplar execution↔fleet); se filtra por `route_id` (o se filtra en la app sobre los items).
`route_id` = `DriverRoute.id` (UUID v7), SIN FK (desacople) → la app manda un id válido.

**Patrón clave: AUTO-UPGRADE SIN REGRESIÓN.** La app no depende del deploy para no regresionar.
En `inspection_history_controller.dart`: `perRouteChecklistMode(items)` = algún item trae
`route_id`. `inspectionForCurrentRoute(items, currentRouteId, now)` → si modo por ruta, el
checklist ligado a esa ruta (null sin ruta en curso); si no (backend viejo), cae al criterio
DIARIO. Así: antes del deploy se comporta como diario (como siempre); cuando los checklists
empiezan a traer `route_id`, pasa SOLO a por-ruta. Mismo patrón sirve para cualquier feature
aditiva del backend: campo opcional presente → comportamiento nuevo; ausente → fallback.

**Campos aditivos del cliente agregados A MANO** (igual que `unit_ids` en `DriverRouteStop`):
se editaron `pre_trip_checklist.dart`+`.g.dart` (route_id/plate/driver_name) y
`conduct_pre_trip_checklist_request.dart`+`.g.dart` (route_id), con comentario "al regenerar
viene solo". Evita correr el script de regen (es del dueño). Al regenerar el cliente se pisan
con lo mismo. Ver [[generated-code-build-caveats]], [[api-client-generation]].

**UI (app):** `ChecklistScreen` muestra `_AlDiaView` (verde, estilo "Todo al día" de
mantenimiento) con placa+hora+chofer cuando la salida actual ya tiene inspección; botón
"Rehacer" SOLO en modo diario (en por-ruta, otra ruta muestra el formulario sola). Recordatorio
del inicio (`DailyInspectionReminder` + `DriverHomeInspectionReminder`) también por ruta (no
molesta si en modo por-ruta todavía no hay ruta). Historial (`inspection_history_screen`) muestra
placa (del item o, fallback, la del vehículo asignado) + fecha + hora (`performed_on`, HH:mm).

**Hora de entrega en paradas:** `stop_timeline_tile` y `stop_detail_screen` muestran
"Entregada HH:mm" / "Fallida HH:mm" desde `DriverRouteStop.settledAt` (lo pone el backend; sin
señal una parada recién resuelta no tiene hora aún → sale sin hora hasta que confirme). Pendiente
sigue con ETA (`etaAt`). Ver [[driver-fleet-ops-cycle]], [[driver-tracking-count-single-source]].

**Herramienta útil:** `mcp__claude-vscode__getDiagnostics` da los errores/warnings del
analizador del IDE SIN correr `flutter analyze` (respeta la regla "el dueño corre flutter") y
el hook los muestra tras cada Edit → se puede dejar el código con 0 issues antes de entregarlo.
