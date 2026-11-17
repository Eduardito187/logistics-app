---
name: driver-map-nav-cadence-batch
description: "nov 2026 — lote mapa/GPS del chofer: tap de push/isla va al seguimiento del home (no pantalla suelta con X), gate resiliente (no 'camión no asignado' por blip), cadencia GPS 2s captura/10s envío; ruta por calles y km = backend (OSRM deploy)"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-17T04:59:35.786Z
---

Lote del dueño (nov 2026) sobre el mapa/seguimiento del chofer. Triaje app vs backend:

**App-side (HECHO):**
- **#6 Tap en la push/isla → abría `ActiveDeliveryScreen` EMPUJADA** (con "X" de cerrar, sin barra de
  navegación, y se APILABA/duplicaba el mapa al tocar varias veces). Fix: `shortcutNavigatorProvider`
  (`app_shortcuts_provider.dart`) detecta si la ruta es la ACCIÓN ESTRELLA del rol (`centerActionFor`) y en
  vez de `router.push` hace `router.go('/home')` + `homeTabProvider.set(kHomeCenterTabIndex=2)` → cae en la
  pestaña central (seguimiento del chofer, con header + barra). Y `ActiveDeliveryScreen` oculta la "X"
  cuando `!Navigator.canPop()` (es la pestaña central, no una pantalla empujada). `kHomeCenterTabIndex` en
  `app_nav.dart`.
- **#2 "Camión no asignado" + mapa no carga por momentos**: el gate (`DriverVehicleGate`) mostraba
  `NoAssignment` ante un error TRANSITORIO de `my-crew` aunque ya tenía el camión. Fix: usa `crew.value`
  (último camión conocido, se conserva en error/reload) → un blip de red NO desasigna; solo bloquea si NUNCA
  hubo camión. (Si además el backend desasigna de verdad, el tiempo real lo corrige.)
- **#4 Camión salta en el mapa / cadencia**: el marcador se movía solo al ENCOLAR (cada 15 s). Bajado a
  **2 s captura / 10 s envío en batch** (`TrackingProfile.moving`: interval/minEnqueueInterval 2 s,
  flushInterval 10 s; `movingSaving` el doble = 4 s/20 s) + `minEnqueueMeters` 25→8 (encola casi cada
  lectura en marcha). El teléfono manda en lote cada 10 s (no por punto) y el backend desglosa per-punto.
  Tests de `tracking_profile`/`truck_tracking_service`/`motion_detector` actualizados (brechas 20s→3s donde
  acumulan bajo los 10 s; 15s→2s; iOS filter `>0`).

**Backend (DERIVADO a logistics-e8, en marcha; UNBLOCK = DEPLOY):**
- **Ruta por CALLES (route_geometry)**: código listo, falta deploy (OSRM, default público funciona; además
  auto-sana geometría degenerada). Hoy sale recta → "pasa por las casas".
- **Reroute DESDE la posición actual + al desviarse**: el off-route ya se evalúa per-punto en la ingesta; el
  reroute es posición→próxima parada (recta en tiempo real + polilínea por calles cacheada por el scheduler
  cada minuto). Pedí (y aceptó) que la polilínea por calles se **regenere async al desviarse** (no esperar
  el minuto). Requiere: plan con geometría válida + envío A BORDO (hasCargo) + deviation.enabled.
- **Datos stale (767 km, SO-900001/María Quispe/La Paz)**: NO es el TodayScenarioSeeder (ese es coherente,
  chofer@dismac.test). Es la demo de La Paz (ShipmentsDemoSeeder/PlanningDemoSeeder) sin telemetría → el
  camión no está sobre la ruta y el km no baja. Backend le agrega telemetría coherente (opción b).
- **km restante**: baja con OSRM + posiciones reales (deploy).
- **Unidad de velocidad**: la app manda `speed_mps`; el ping del backend menciona `speed_kph` → mismatch a
  alinear (pendiente de su respuesta); no bloquea (off-route es por distancia).

**#1 Smartwatch**: ver [[wear-os-data-layer]]; la notificación espejada depende del ajuste por-app del
reloj, el tile requiere instalar el `:wear`. No se tocó en este lote.

Ver [[driver-tracking-count-single-source]], [[pretrip-gate-and-route-drawing]], [[gps-ping-endpoint]],
[[feedback-no-over-derivar-backend]].
