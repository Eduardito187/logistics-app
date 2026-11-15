---
name: driver-pending-odometer-checklist-load
description: "nov 2026 — HECHOS: botón 'Cerrar ruta del día' se oculta tras el odómetro de llegada; sin 'Rehacer' en checklist; entregados fuera de 'cargar al camión' + cliente/pedido; isla = misma parada que la vista; barra animada por distancia; 'Correo válido.'"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-14T13:41:47.553Z
---

Los 3 pendientes del 2026-11-13 quedaron **implementados el 2026-11-14** (analizador limpio; `flutter
test` no lo corrí yo, lo corre el dueño), junto con otros pedidos del mismo día:

1. **"Cerrar ruta del día" se oculta** cuando la salida en curso ya tiene su odómetro de llegada:
   `arrivalRecordedForCurrentTrip` (`route_km_today.dart`) = hay `arrival` de hoy posterior a la última
   `departure` de hoy. Así reaparece en una segunda salida. Widget `_CloseRouteButton` en
   `driver_route_screen.dart` (consulta `todayOdometerReadingsProvider` solo con la ruta completa).
   `OdometerScreen(closeOnSaved: true)` cierra al guardar. Es inferencia por hora: pedido al backend
   `route_id` en odómetro + 409 a segunda llegada.
2. **Sin botón "Rehacer"** en el checklist (se borraron `allowRedo`/`_forceForm`). Por ruta: otra ruta sin
   inspección muestra el formulario sola. Ojo: en modo diario (backend sin `route_id`) ya no hay forma de
   re-inspeccionar el mismo día. Ver [[checklist-por-ruta-y-hora-entrega]].
3. **Carga del camión honesta** (`load_scan_screen.dart`): excluye entregas `delivered`/`failed` y las de
   paradas ya resueltas; título = cliente + "Pedido X" tomados de `driverRouteProvider` (sin llamada
   nueva); "Envío N" solo si el envío no está en la ruta. Pedido al backend para que venga bien de origen.

Otros cambios del 2026-11-14:
- **Isla/chip = la MISMA parada que la vista** (`RouteLiveStatus.chipText` = `deliveryPosition/stopCount`,
  p. ej. "4/7" con "Parada 4 de 7"). Reemplaza lo de [[driver-tracking-count-single-source]] (antes eran
  las atendidas, "3/7", y el dueño lo leyó como desactualizado). `IslandOverlay.kt` pinta el `chip` de
  Dart; el festejo sigue con `completed`.
- **Barra de progreso animada por distancia**: el tramo en curso se pinta verde claro según lo que falta a
  la parada (`LegProgress` en `active_delivery_screen.dart`: muestra cada 10 s, nunca retrocede, 100 % =
  mayor distancia vista; `RouteProgressBar(legFraction:)` anima 1,8 s). Al entregar pasa a "hecho".
- **Recuperar contraseña**: el aviso dice solo "Correo válido." (sin "si el correo existe…").
- Evidencia con imagen en "Ver pedido" (`DeliveryEvidenceItem.url`, enlace firmado ~2 h).

**How to apply:** el dueño pidió hacer estos puntos **solo, sin agentes** (ver [[feedback-working-style]]).
Recojo en tienda: [[store-pickup-customer-flow]].
