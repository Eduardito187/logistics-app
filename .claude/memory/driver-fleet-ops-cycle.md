---
name: driver-fleet-ops-cycle
description: "Ciclo chofer (nov 2026): auto-enfoque del mapa en reposo, geocerca llegada, odómetro solo salida/llegada, inspección diaria diésel + historial + recordatorio + bloqueo crítico, km recorridos, y fixes UI."
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-11T14:08:11.287Z
---

Nov 2026, pedidos del dueño sobre la operación del chofer. Todo app-side, suite entera verde
(2026 unit + 6/6 e2e).

**Mapa — auto-enfoque en reposo** (`features/driver/presentation/widgets/active_delivery/delivery_map.dart`):
cuando NI el usuario mueve el mapa NI el camión se mueve por **6 s** (umbral quietud 12 m), el mapa se
acerca suave al camión. Nunca con gesto en curso, camión en marcha, otra animación (`_mover.isAnimating`),
ni en modo seguir. Regla PURA testeable `shouldAutoFocus({now, truckStillSince, lastGestureAt, follow,
autoFocused, animating, window})` + `_trackStillness` + `Timer.periodic(1 s)`. `AnimatedMapMover` ganó
`isAnimating`. Respeta reduce-motion. Tests: `test/features/driver/widgets/auto_focus_test.dart`.

**Mapa — geocerca de llegada** (`delivery_status_card.dart`): `arrivedAtStop(remaining)` = `!offRoute &&
meters <= kArrivalMeters(60)` → "Llegaste a destino" (verde) en vez de "Faltan 30 m". "Fuera de ruta"
(`offRoute`, umbral 150 m) YA existía. Reusa `remainingToStop`/`estimateRemaining` (proyección sobre el
trazo en `route_navigation.dart`, ya probada).

**Odómetro SOLO salida/llegada** (decisión del dueño): la lectura de SALIDA va en el **checklist
pre-salida** (campo "Odómetro de salida", `source: departure`, best-effort); la de LLEGADA en un botón
**"Finalizar ruta (odómetro de llegada)"** en "Mi ruta de hoy" cuando no quedan paradas pendientes
(`OdometerScreen` parametrizada `source/title/intro/initialNote`, `source: arrival`). Se QUITÓ el odómetro
como tarea suelta del inicio. Validación local `odometerBelowLast(km, readings)` (solo avanza, mismo guard
del backend adelantado). `arrival` lo agregó el backend a ambos enums (parché a mano el cliente generado).

**Inspección diaria diésel** = el checklist pre-salida ES la inspección diaria. Ítems reescritos a diésel:
motor, aceite, agua/refrigerante, frenos, llantas, luces, fugas, combustible, extintor, documentos.
**Bloqueo por ítem crítico** `_criticalItems = {brakes, engine}`: si fallan → snackbar ROJO "NO apto para
salir" (se guarda igual). **Historial por camión** (`InspectionHistoryScreen`, reusa
`GET /app/fleet/pre-trip-checklists?vehicle_id=…` vía `fleetListPreTripChecklists`) + **recordatorio diario**
(`DailyInspectionReminder` + wrapper `DriverHomeInspectionReminder` en el INICIO del chofer, usa
`assignedVehicleIdProvider`; helper `inspectionDoneToday`). Backend: NO hizo falta nada nuevo.

**Km recorridos de la ruta** = odómetro llegada − salida del día; tarjeta "Kilómetros de hoy" en
`my_day_screen.dart` (helper puro `routeKmToday(readings, now)`).

**Fixes UI del chofer (mismo ciclo):**
- Snackbar de login se **filtraba al home** (el ScaffoldMessenger raíz de `app.dart` lo arrastra entre
  pantallas): fix = limpiar `messengerKey.clearSnackBars()` al pasar `sessionProvider` null→activa.
- "Estado de la entrega" (stop detail) daba 404 feo: degrada a "Sin movimientos registrados todavía."
  (sin "Reintentar"; es complementario).
- "Mi ruta de hoy" daba 422 "Revisá los datos" al re-armar una ruta YA armada: se OCULTA "Armar ruta del
  día" del header cuando la ruta ya tiene paradas (el 422 venía vacío del backend).
- "Entregado (prueba de entrega)" → **"Entregar"**; título POD "Prueba de entrega" → **"Comprobante de
  entrega"**; rol chofer "Prueba de entrega…" → "Entrega…" (el dueño no quiere "prueba"). "Imprimir prueba"
  de Ajustes se dejó (ahí SÍ es prueba de impresora).

**Pendiente app (próximo ciclo, requiere dispositivo):** muestreo GPS adaptativo, modo batería,
suavizado/snap-to-road, interpolación del marcador (tocan el servicio de GPS en 2.º plano). **Delegado al
backend** (`docs/backend-requests/2026-11-11-telemetria-seguimiento-roadmap.md`): breadcrumbs server-side,
alertas de telemetría, ETA con tráfico, vista multi-camión del supervisor. Roadmap vivo en
`docs/roadmap-seguimiento-flota.md`. Ver [[product-ux-decisions]], [[code128-label-scanning]].
