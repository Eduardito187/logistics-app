---
name: gps-ping-endpoint
description: "El GPS del chofer va por POST /app/tracking/shipments/{id}/position (cola offline), NO por /app/telemetry/pings; la telemetría buffered (Ola 6) no afecta a la app"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-14T13:41:23.457Z
---

El GPS en vivo del chofer **no usa** `POST /app/telemetry/pings`. Va por
`POST /app/tracking/shipments/{shipmentId}/position`, **una posición por request**, encolada en la cola
offline con kind `ingestTruckPosition` (`truck_tracking_service._flush` → `offline_dispatcher._ingestTruckPosition`
→ `api.tracking.ingestTruckPositionFromApp`).

`/app/telemetry/pings` está en el cliente generado (`telemetry_client.recordAppVehiclePings`,
`VehicleTelemetryRepository.recordVehiclePings`) pero **nadie lo llama**: código muerto.

**Why:** el backend (logistics-53, 2026-11-14) pasó `/app/telemetry/pings` a ingesta por buffer (429 +
`Retry-After`, `data.buffered`, `duplicate_count` siempre 0) y preguntó si chocaba con la cola de pings.
No choca: la app no usa ese endpoint.

**How to apply:** no re-investigar esto. Si algún día se migra el GPS a `/telemetry/pings` en lote, la
política ya lo soporta (`SyncRetryPolicy`: 429 transitorio, respeta `Retry-After` hasta 30 min, la fila
queda `pending` y se reenvía igual; la cola limpia con cualquier 2xx, no mira `duplicate_count`); faltaría
manejar el 207 por ítem. Ver [[perf-rebrand-stability-fixes]].

**ETA y ruteo = BACKEND, no la app (2026-11-16):** decisión del dueño. La app SOLO aporta la ubicación (lat/lng/reported_at por `ingestTruckPositionFromApp`, lote idempotente) y muestra lo que el backend empuja. El backend, con su motor de ruteo, detecta salida de ruta (vs `plan.route_geometry`), re-rutea a la siguiente parada y calcula la ETA (deriva velocidad de 2 posiciones seguidas). La app NO calcula ruta ni ETA de ruta; único cálculo local permitido = el último tramo cosmético "Faltan X km · Y min" desde el GPS. Pedido en `docs/backend-requests/2026-11-16-eta-viva-y-salida-de-ruta.md`: eta_at por parada en todas las superficies (plan/ruta chofer/lookup/detalle, una sola verdad = ventana al cliente), recálculo vivo por socket (`eta.updated` o eta_at dentro de `route.updated`), `off_route`/`rerouted` del backend (hoy el cartel "Fuera de ruta" del chofer se decide local → pasar a backend). Opcional: enriquecer el payload con speed_mps/heading_deg/accuracy_m si el backend los pide.
