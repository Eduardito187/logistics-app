---
name: pretrip-gate-and-route-drawing
description: "nov 2026 — bloqueo pre-salida (sin checklist no se entrega), trazo de respaldo por paradas y dibujo de reruteo/fuera-de-ruta en el mapa del chofer; ruta/off-route reales dependen del backend"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-16T19:32:42.110Z
---

Pedidos del dueño (2026-11-16), con foto del seguimiento del chofer:

## 1. Bloqueo por inspección pre-salida (pre-check) — HECHO en app
Si falta el checklist pre-salida de la salida en curso, el chofer **no puede iniciar las entregas**.
- `preTripChecklistPendingProvider` (en `inspection_history_controller.dart`): combina
  `assignedVehicleIdProvider` + `driverRouteProvider.id` + `inspectionHistoryProvider(vehicleId)` con
  `inspectionForCurrentRoute` (modo por ruta / diario). **Fail-open**: solo bloquea cuando SE SABE que
  falta (sin trabar al chofer por una lectura que no llegó; offline invisible).
- `DeliveryActionsBar`: si pendiente → reemplaza las acciones por `_ChecklistRequiredBar` ("Hacer
  inspección pre-salida" → `/driver/checklist`). Test: `pre_trip_checklist_gate_test.dart`.
- Derivado al backend (defensa en profundidad): rechazar POD/store-drop si falta el checklist (análogo a
  `fit_to_dispatch`/UnfitVehicleDispatch).

## 2. No se dibuja la ruta del viaje ni el reruteo por desvío
Diagnóstico (código backend, `GetDriverRouteHandler`): `route_geometry` = geometría del PLAN
(`RouteGeometryReader`) y `off_route`/`reroute_geometry` = motor de ETA en vivo (`LiveRouteStateReader`,
paquete telemetry: `OffRouteEvaluator`/`RerouteGeometryCalculator`). Ambos llegaban **null** → el mapa caía
a línea recta (768 km SCZ↔La Paz) y nunca reruteaba. Es **backend/infra** (geometría del plan sin calcular
o paradas sin geocodificar; motor de ETA sin posiciones o job `RefreshVehicleEtas` sin correr). La app NO
calcula rutas por calles ni desvíos.

HECHO en app (`delivery_map.dart`), mitiga y usa lo del backend apenas llegue:
- **Respaldo de trazo** si `route_geometry` null: une las paradas en orden de secuencia (`_stopsPath`), así
  "la ruta del viaje" siempre se ve.
- **Dibuja el reruteo**: `_isOffRoute(driver)` = `route.offRoute` del backend si lo manda, si no detección
  local (distancia del camión al trazo por calles > `kOffRouteThresholdMeters`=150 m). Cuando está fuera de
  ruta, pinta `reroute_geometry` del backend (ámbar) o, si no llegó, línea directa camión→destino
  (`_rerouteLine`). La tarjeta ya mostraba la pastilla "Fuera de ruta".

Pedido al backend: `docs/backend-requests/2026-11-16-ruta-del-viaje-y-fuera-de-ruta-no-se-generan.md`
(geometría al publicar + geocodificar paradas; motor de ETA con posiciones; seeder camión+paradas misma
ciudad). Enviado a logistics-e8.

**Causa raíz confirmada por el backend (staging, 2026-11-16):**
- (1) `route_geometry` NO era null: era **degenerada** (LineString con 4 coords IDÉNTICAS = un punto) y
  stale (paradas en otra ciudad). El reader la servía porque validaba solo `coords>=2`. Fix backend: el
  reader exige **≥2 puntos DISTINTOS** (guardia `isDrawable`); si es degenerada la ignora y cae a la recta
  entre las paradas reales. Sin cambio de shape; falta su deploy.
- (2) `off_route`/`reroute` null **no es bug**: la maquinaria está bien (scheduler `telemetry:refresh-etas`
  corre cada minuto). No produce salida porque en staging el vehículo **no tiene posiciones GPS**
  (`telemetry_pings=0`). En prod el app manda GPS continuo → funciona. Para demo off-route hay que sembrar
  posiciones.
- El dueño decidió **NO** forzar el checklist server-side: basta el gate del app.
- **Endurecimiento app (por la geometría degenerada):** mi respaldo entraba solo con `<2 puntos`; con 2
  idénticos dibujaba un punto. Agregada guardia `_hasTwoDistinctPoints` (≥2 puntos distintos) en
  `delivery_map.dart` para trazo por calles, respaldo por paradas y reroute → iguala el `isDrawable` del
  backend. Así mi red funciona aunque llegue geometría basura, antes e independiente de su deploy.

Ver [[driver-tracking-count-single-source]], [[checklist-por-ruta-y-hora-entrega]], [[gps-ping-endpoint]],
[[feedback-no-over-derivar-backend]].
