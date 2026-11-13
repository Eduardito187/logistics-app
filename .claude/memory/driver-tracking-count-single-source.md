---
name: driver-tracking-count-single-source
description: "nov 2026 — etiquetas quedan 'Cargada' tras entregar (bug backend Loaded→Delivered) y el app pasó a avance ITEM POR ITEM (RouteProgress); conteo/completada/mapa/acciones coherentes"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-13T21:33:15.338Z
---

**Síntomas del dueño (nov 2026, staging):** "entregué varios pedidos y las etiquetas
siguen Cargadas"; "entregué 5 de 7 pero figura 6 entregado"; "entregué el 6º de 7 y salió
ruta completada"; "entrando a una parada ya entregada siguen las acciones"; "no entiendo
los colores del mapa"; "el progreso salta de golpe"; "el seguimiento debe seguir hasta el CD".

**Causa raíz BACKEND (solo la arregla el backend, auditado con archivo:línea):**
- **Etiqueta/envío "Cargada" tras POD:** `VisibleStatus::allowedNext` NO permite
  `Loaded→Delivered` (`tracking/.../VisibleStatus.php:60-68`); `Delivered` solo desde
  `OnTheWay`, que SOLO lo emite el inicio de ruta (`StartDriverRouteHandler` → `markDeparted`).
  El POD no emite salida. La proyección descarta `ShipmentDelivered` en silencio si no aplica
  (`ProjectExecutionEventHandler.php:58-60`). → tracking atascado en Cargada aunque el
  `Delivery` quedó Delivered y la parada cerrada.
- **Conteo/"completada" de más:** `completed_stops = settledCount()` cuenta Failed+Rescheduled
  como completadas (`RouteStopStatus::isTerminal == !Pending`, `RouteStopStatus.php:32-35`);
  la ruta pasa a `completed` cuando no quedan PENDING (`VehicleRoute.php:535-546`). Una fallida
  infla el conteo y completa la ruta con pedidos sin entregar.
- **Firma/foto NO están** en `RouteStopView`; sí en `GET /app/deliveries/{id}` (`pod_photo_url`,
  `pod_confirmation`). **unload ("descargar producto") = vestigial** (ShipmentUnloaded lo ignora
  la proyección). **Re-ruteo:** hay ingesta `/app/telemetry/pings` + `/vehicles/{id}/track`, pero
  NO hay detección de desvío ni recálculo en vivo. Todo pedido: `docs/backend-requests/2026-11-13-tracking-entrega-conteo-reruteo.md` (enviado a logistics-42).

**Arreglo APP (esta sesión) — regla NUEVA: fuente ÚNICA de avance ITEM POR ITEM.**
`lib/features/driver/domain/route_progress.dart` (`RouteProgress.of(route, settled)`) cuenta
el estado EFECTIVO de cada parada (`effectiveStopStatus` = backend + lo resuelto en este
teléfono), con fallback a los agregados del backend SOLO si `stops` viene vacío. `isComplete`
= sin pendientes (total>0), NUNCA `route.status`/`completed_stops`. Lo usan: `RouteSummary`
(ahora ConsumerWidget, +fila "no entregadas"), `MyDayStats.fromRoute`, `DeliveryStatusCard`
(barra), `driver_route_screen.allDone`, entrega en curso. **Nunca volver a usar
`route.completedStops`/`stopsRemaining`/`route.status` para avance/completitud.**

**Footgun de "Siguiente entrega" (nov 2026):** `DeliveryActionsBar` calculaba "cerrada" mirando
`deliveryStateProvider(shipmentId)` (estado de la ENTREGA del envío). Si el backend devolvía el
envío como `delivered` por su cuenta, una parada aún PENDIENTE mostraba "Siguiente entrega" y al
tocarla hacía `settle(completed)` → marcaba entregada una parada que el chofer no entregó (el
dueño: "le di siguiente entrega y me marcó todos entregados sin entregar el 7º"). FIX: la barra
usa SOLO el estado EFECTIVO de la parada (`effectiveStopStatus`); el POD/fallida ya hacen
`settle`, así que "Siguiente entrega" solo refresca (nunca marca por su cuenta). El botón "Cerrar
ruta del día" (odómetro de llegada) solo aparece con `isComplete` y lleva un texto que explica
que cierra la ruta y calcula los km.

Backend (logistics-42, nov 2026, en working tree sin deploy): #1 `VisibleStatus::allowedNext`
ahora admite Delivered/Failed desde InProgress/Loaded (el POD ya no se descarta); #2
`completed_stops` = SOLO entregadas + nuevos `failed_stops`/`rescheduled_stops`; #3 `GetRouteStop`
expone `pod_confirmation`+`pod_photo_url`. Además el outbox estaba congelado por un lock de
scheduler de 24h (withoutOverlapping sin expiración) → por eso los `execution.*` no se
despachaban; acotado a 10 min (sin deploy). **Desatasco manual en staging:** `ssh oci`
(solo desde WSL: `wsl -d Ubuntu-22.04 bash -lc "ssh oci '…'"`; en Git Bash de Windows no está
el host) → `docker exec logistics-staging-app-1 php artisan schedule:clear-cache` (NO
`schedule:clear-mutex`, no existe en esta Laravel) → borra los mutex atascados, incl.
`logistics:outbox:pump`. Esto descongela el pump; las transiciones en sí las arregla el deploy. La app ya consume todo (item-por-item no depende de los nuevos
contadores; los campos de parada entran al regenerar el cliente).

**Live Updates / isla (nov 2026):** `route_live_status_builder` ahora cuenta las atendidas
ITEM POR ITEM (estado efectivo), NUNCA `route.completedStops` (se quitó el `max` con el conteo
del backend). El render nativo es correcto: `LiveUpdatesChannel.kt` dibuja segmentos=`stopCount`
y puntos=`completed` (MAX_POINTS=15, no es el tope). "Parada 1 de 7 congelado / solo 4 puntos"
= tras REINICIAR la app el `settled` en memoria se pierde y el route sheet SIN deploy devuelve
todo pendiente/parada 1 → lo fija el DEPLOY de #1/#2 (o persistir `settled`, no hecho: moot
post-deploy). Throttle de la distancia bajado de 30 s → **10 s** (`RouteLiveUpdatesController.minUpdateInterval`,
pedido del dueño "tiempo real"; igual lo limita la cadencia del GPS). **Isla/chip compacto = el
contador de AVANCE/ATENDIDAS ("6/7" = `completedCount/stopCount`, donde
completedCount = entregadas+fallidas, igual que la barra), SIN la hora** (`RouteLiveStatus.chipText`
= `deliveredCounterText`; antes era `stopIndex/stopCount · hora`). En la pastilla propia
`IslandOverlay.kt` la compacta muestra camión + ese contador (ajustada a su contenido al sacar la
hora) y **festeja al entregar** (`celebrate()`: el camión se pone VERDE y vuelve a rojo ~2,5 s con
ArgbEvaluator + el contador da un bote; se dispara cuando `completed` sube, guardado en
`lastCompleted`). La pastilla del SISTEMA no se puede animar (la dibuja el SO), pero su chip también
quedó count-only. **"Parada N de M" = ordinal de la entrega por AVANCE (`attended+1`), NO la secuencia de la parada**
(`DeliveryStatusCard` y `RouteLiveStatus.title`/`deliveryPosition`): con entregas fuera de orden la
secuencia confundía ("Parada 1 de 7" con 6 hechas → debe decir "Parada 7 de 7"). **Code-review
(nov 2026) endureció:** el builder de la isla ya NO mira `route.status==completed` (item por item
con `currentStopOf`, como el resto); la tarjeta usa `progress.total` para total+posición+barra (no
`route.totalStops`, evita divergencia); el "sin entregas en curso al cargar" se arregló con una
re-verificación de una sola vez en `ActiveDeliveryScreen` (el prefetch cacheaba un fetch
transitorio); el checklist por-ruta espera a que cargue la ruta antes de permitir enviar (si no iría
`route_id=null` y nunca cuadraría). La **pastilla alrededor de
la cámara la dibuja el SISTEMA** (Android 16 Live Update / Dynamic Island iOS): la app NO controla
su tamaño. `IslandOverlay.kt` es la pastilla propia (overlay), que SÍ controlamos, pero los
screenshots del dueño eran la del sistema (barra de progreso con puntos = ProgressStyle del SO).

**Leyenda del mapa quitada** (`route_legend.dart` BORRADO): el dueño primero la pidió y después
la quitó — los colores ya están en los marcadores (`StopPin` por estado efectivo), la caja solo
tapaba mapa. **Evidencia del cliente deduplicada por tipo** en el modal "Ver pedido"
(`delivery_sheet._EvidenceSection._dedupeByKind`): el backend graba una evidencia por UNIDAD →
firma/documento salían repetidos; se muestra 1 por tipo con el peor estado. **Imágenes de
producto vacías** = el backend no puebla `image_url` de esos SKU (gap de catálogo, delegado).

Otros cambios app: `stop_detail_screen` oculta Entregar/Entrega fallida/Descargar cuando la
parada está resuelta (estado efectivo) y muestra `pod_photo_url`; se QUITÓ "Descargar
productos" (unload obsoleto) del detalle y la entrega en curso. Mapa (`StopPin` acepta
`status` efectivo; `RouteMap`/`DeliveryMap` muestran paradas ya marcadas en verde/rojo +
leyenda `route_legend.dart`). `RouteProgressBar` ahora ANIMA (TweenAnimationBuilder, sin
saltos). Rastreo: `driver_tracking_autostart._shipmentToTrack` ya NO apaga al completar la
ruta — sigue con el último envío (regreso al CD) hasta el logout (el seguimiento a nivel ruta
lo completa el backend). Ver [[pod-scanner-vehicle-hardening]], [[driver-fleet-ops-cycle]],
[[no-label-mutations-rule]].
