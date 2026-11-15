# Tracking de entrega, conteo de ruta, firma/foto por parada, unload obsoleto y re-ruteo

**Fecha:** 2026-11-13 · **Pide:** app interna (chofer) · **Para:** backend `logistics`
**Prioridad:** 🔴 1 y 2 son CRÍTICOS (datos de operación incorrectos en producción).

Reportado por el dueño en terreno (staging): "entregué varios pedidos y las etiquetas
siguen como **Cargada**, no se actualiza el tracking"; "entregué 5 de 7 pero figura 6
entregado y el 6º debería estar pendiente"; "entregué el 6º de 7 y me salió **ruta
completada**". Auditoría del código del backend (solo lectura) confirma las causas con
`archivo:línea`. La app ya se corrigió donde le corresponde (ver "Lado app" al final); lo
siguiente es del backend.

---

## 1. 🔴 CRÍTICO — El POD no actualiza el tracking: la etiqueta/envío queda en "Cargada"

**Causa raíz (confirmada):** la máquina de estados del tracking visible no permite
`Loaded → Delivered`, y la proyección descarta el evento en silencio.

- `ShipmentTracking` / `VisibleStatus::allowedNext` (`tracking/src/Domain/ValueObject/VisibleStatus.php:60-68`):
  `InProgress→Loaded`, `Loaded→[OnTheWay, Cancelled, Rescheduled]`, `OnTheWay→[Delivered, Failed, …]`.
  **`Delivered` solo es alcanzable desde `OnTheWay`.**
- La proyección es tolerante: si `!canApply` **se saltea sin error**
  (`tracking/src/Application/Command/ProjectExecutionEvent/ProjectExecutionEventHandler.php:58-60`;
  `canApply` en `ShipmentTracking.php:155-157`).
- `OnTheWay` solo lo emite el **inicio de ruta** (`StartDriverRouteHandler.php:56-69` → `markDeparted`
  → `ShipmentDeparted` → `VisibleStatus::OnTheWay`). El POD **no** emite salida; y el auto-open del
  POD abre la entrega directo en `Loaded` sin emitir salida (`Delivery.php:98-120`).

**Resultado:** si el envío quedó en `LOADED` y nunca recibió `OnTheWay` (chofer que entrega sin
"iniciar ruta", o envío agregado/reasignado después del inicio), cuando llega `ShipmentDelivered`
la proyección lo **descarta** y el tracking se queda en **Cargada para siempre**, aunque el POD fue
exitoso y el `Delivery` quedó `DELIVERED` y la parada cerrada (`RecordProofOfDeliveryHandler.php:71-103`).

**Pedido:** que un `ShipmentDelivered` **nunca** se pierda por la guardia de transición. Opciones
(elige backend, preferimos la robusta):
- permitir `Delivered` también desde `Loaded` (y `InProgress`) en `VisibleStatus::allowedNext`; **o**
- que la proyección auto-avance por los estados intermedios al recibir `Delivered`; **o**
- que `RecordProofOfDeliveryHandler` emita la salida (`markDeparted`) antes de `Delivered` para
  garantizar `OnTheWay`.

**Timeline de la ETIQUETA (`labels_emitted`):** la etiqueta no tiene estado propio; "Entregada" en
`LabelLifecycle.php` sale de un scan `PROOF_OF_DELIVERY` con el **mismo `unit_id`** de la etiqueta. Si
el POD se ancla a un solo `shipment_unit` (p. ej. `DriverDeliveryController.php:56-59` toma el primer
unit), las demás etiquetas del envío nunca marcan entregada. **Pedido:** derivar "entregada" de la
etiqueta del estado del `Delivery`/tracking del envío, no solo del match de `unit_id`.

---

## 2. 🔴 CRÍTICO — Conteo de ruta engañoso y "completada" de más

**Causa (confirmada):**
- `completed_stops = VehicleRoute::settledCount()` (`DriverRouteView.php:74` → `VehicleRoute.php:512-515`)
  cuenta paradas con `status->isTerminal()`, y `RouteStopStatus::isTerminal() == ($this !== Pending)`
  (`RouteStopStatus.php:32-35`). O sea **cuenta Completed + Failed + Rescheduled como "completadas"**.
  Por eso "5 entregadas" podía verse como 6: una fallida/reprogramada infla `completed_stops` y
  contradice `stops[].status`.
- `VehicleRoute::refreshStatus()` (`VehicleRoute.php:535-546`) pone `Completed` cuando
  `stopsRemaining()==0`, y `stopsRemaining` cuenta **solo `PENDING`** (`VehicleRoute.php:480-507`). Una
  parada `Failed`/`Rescheduled` deja de ser pending → la ruta se marca **completada con pedidos sin
  entregar** (el "6 de 7 y ya completada"). `close()` además marca completada sin exigir todo entregado
  (`VehicleRoute.php:159-189`).

**Pedido:** separar conceptos en el read-model de la ruta (`DriverRoute`):
- `completed_stops` = **solo entregadas** (status Completed).
- agregar `failed_stops` y `rescheduled_stops` (o un `attended_stops` = resueltas).
- revisar el `status`: no llamar `completed` a una ruta con paradas no entregadas, o distinguir
  "cerrada por el chofer con pendientes" de "todo resuelto".
- idealmente que `stops.length == total_stops` siempre (la app cuenta item por item sobre `stops[]`).

---

## 3. Firma y foto del POD en el read-model de la parada

Hoy `RouteStopView` (`…/Application/ReadModel/RouteStopView.php:33-50, 102-124`) y `GetRouteStop`
**no** exponen firma/foto; están solo en `GET /app/deliveries/{shipmentId}` (`DeliveryView`:
`pod_confirmation`, `pod_photo_url`, `pod_photo_path`) y en `/evidence`.

**Pedido:** enriquecer `RouteStopView`/`GetRouteStop` con `pod_confirmation` + `pod_photo_url(s)` (y refs
de evidencia si aplica) para la parada entregada, así la app las muestra al reentrar sin una segunda
llamada. Nota: la "firma" se guarda como `confirmation` (string), no como imagen; si debe verse la
imagen de la firma, exponer su URL también. (La app ya muestra `pod_photo_url` desde el estado de la
entrega — ver "Lado app".)

---

## 4. "Descargar producto" (unload) — confirmar obsolescencia

Confirmado que el unload es **vestigial/opcional**: `POST /app/deliveries/scans/unload`
(`RecordUnloadScanController`, `Delivery::recordUnloadScan` `Delivery.php:355-383`) solo agrega un scan y
graba `ShipmentUnloaded`, que **la proyección ignora** (`VisibleStatus::fromExecutionEvent` default null).
No es prerequisito del POD (el POD va directo `Loaded→Delivered`) y encima exige `Loaded/InTransit`
mientras el POD acepta también `Pending/Prepared` → puede fallar donde el POD ya no.

**Pedido:** declararlo **obsoleto** (o explícitamente opcional, como telemetría de descarga). **La app ya
quitó el botón "Descargar productos"** del detalle de parada y de la entrega en curso.

---

## 5. Seguimiento del regreso al CD + re-ruteo en tiempo real (a futuro, ambicioso)

Pedido del dueño: el seguimiento del camión debe continuar **en todo momento hasta el regreso al centro
de distribución** (para reasignar ruta o dar descanso), aunque la ruta figure completada; y, ambicioso,
**detectar cuando el chofer no sigue la ruta planeada y recalcular una ruta nueva en tiempo real**.

Estado del backend (confirmado):
- **Ingesta de posición:** ✅ existe. `POST /app/telemetry/pings` (`RecordAppVehiclePingsController`),
  traza por vehículo `GET /app/.../vehicles/{id}/track`, flota en vivo, ETA dinámica, geocercas/alertas
  (`routes/api/telemetry.php:40-77`). La app ya encola posiciones (`ingestTruckPosition`).
- **Seguimiento del regreso a nivel RUTA:** hoy los breadcrumbs se agrupan por **envío**. No hay un canal
  de "regreso al CD" sin envío. **Pedido:** un estado/fase de ruta `returning`→`closed` (hoy
  `completed` se usa para ambas) y/o aceptar pings de ruta sin envío hasta el cierre por odómetro de
  llegada, para seguir mostrando el camión en el regreso. (La app, mientras tanto, sigue rastreando el
  último envío de la ruta hasta el logout — ver "Lado app".)
- **Detección de desvío:** ❌ no existe (sin `deviation/off-route`). **Pedido:** servicio que compare la
  traza real contra el `LineString` del plan y emita un evento de desvío.
- **Recalcular/reasignar ruta en vivo:** ❌ no existe (solo reacción a incidente
  `VehicleRoute::reportIncident` y attach/detach manual de paradas). **Pedido:** comando de
  re-secuenciación/optimización que reescriba las paradas pendientes de la `VehicleRoute` y recalcule
  geometría/ETA, + notificación push al chofer. Es trabajo nuevo; ya existe la base (breadcrumbs +
  geometría del plan + ETA dinámica).

---

## Lado app (ya hecho en esta sesión, para contexto)

- **Fuente única de avance item por item** (`RouteProgress`): resumen, lista, "Mi día", barra de progreso
  y detección de "ruta completada" ahora cuentan el estado EFECTIVO de cada parada (nunca
  `completed_stops`/`status` del backend). Elimina el "5/7 pero 6 entregadas" y el "completada con
  pendientes" **del lado app** (pero el `completed_stops` del backend sigue mal — punto 2).
- **Acciones de parada entregada ocultas** (Entregar / Entrega fallida / Descargar). Se quitó "Descargar
  productos".
- **Mapa:** paradas ya marcadas se muestran con su color (verde/rojo), colores por estado efectivo,
  leyenda de colores.
- **Foto del POD:** se muestra en el estado de la entrega desde `pod_photo_url` (punto 3 la llevaría a la
  parada directamente).
- **Barra de progreso animada** (ya no "salta de golpe").
- **Rastreo del regreso:** la app ya NO apaga el rastreo al completar la ruta; sigue con el último envío
  hasta el logout. El seguimiento a nivel ruta (punto 5) lo haría completo.

El "recorrido transcurrido" (traza real dibujada) la app lo puede consumir de
`GET /app/.../vehicles/{id}/track` cuando se priorice; por ahora dibuja el plan + las paradas marcadas.
