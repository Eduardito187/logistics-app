---
name: store-pickup-customer-flow
description: "nov 2026 — recojo en tienda de CLIENTE que retira: buscador por código + escanear etiqueta + entrega igual al chofer (productos, firma, foto obligatoria, documento opcional); pendientes backend; idea futura QR de retiro"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-14T14:00:08.563Z
---

**Decisión del dueño (2026-11-14):** el rol tienda tiene un recojo donde **un cliente real pasa a
recoger su pedido** (distinto del envío almacén→tienda, que es la Recepción). Se busca por **código del
pedido**, y la entrega es **el mismo proceso del chofer**: escaneo de productos, firma del cliente, foto
de entrega **obligatoria**, foto del documento **opcional**; al guardar el pedido queda **entregado**.

**App (hecho, sin compilar por mí):**
- `counter_pickup_screen.dart`: buscador "Código del pedido" (filtra lo YA cargado por código / cliente /
  documento, sin otra llamada) + botón **Escanear etiqueta** → `pickup_label_lookup.dart` (QR: pedido y
  SKU salen del contenido, sin red; Code128: `/app/labels/{id}/resolve`) → `pickup_label_sheet.dart`
  (pedido, producto, cliente y "Entregar este pedido"; si no es de la tienda lo dice).
- `pickup_pod_screen.dart` reescrita: escanear **no entrega**; un botón fijo que cambia con el paso
  ("Escanear productos" → "Registrar entrega" → "Pedido entregado"). Al registrar: evidencia `signature`
  e `id_document` con `client_snapshot`, foto `pod`, y un POD **por producto** con
  `confirmation: FIRMA_DIGITAL`. Se quitó el "QR del cliente o documento" digitado.
- Reutiliza piezas del chofer (pad de firma, `signatureFileStoreProvider`, `SignaturePreview`,
  `EvidencePhotoPreview`, constantes de `pod_screen.dart`). Seam de test: `pickupSignatureCaptureProvider`.
- Lista de productos con nombre, `SKU x` y `Etiqueta …XXXXXX` (`UnitProductRow(showLabelCode: true)`;
  hoy es el `unit_id` abreviado). Estado nuevo `UnitRowStatus.scanned` ("Escaneado").
- Tests: arnés `test/features/store/pickup_pod_support.dart`.

**Pendiente del backend** (`docs/backend-requests/2026-11-14-recojo-en-tienda-aviso-cliente-carga.md`,
enviado a logistics-53): `fulfillment_type`/`ready_for_pickup` para separar recojo de traslado; búsqueda
`q=`; POD de mostrador **sin vehículo** → DELIVERED + permisos del rol tienda (sin confirmar que hoy
funcione); `label_id` en `UnitTracking`; cliente en `/labels/{id}/resolve`. Y: cuando el chofer entrega en
la tienda → hito "listo para retirar" + **acción del servidor que avisa al cliente** (nº de pedido y
productos). La app no integra mensajería ([[app-scope-backend-consumer]]).

**Respuesta del backend (logistics-53, 2026-11-14, revisado en su código):**
- YA existe y la app lo usa con campos aditivos A MANO en el cliente (pendiente regen): `delivery_mode`
  (`home_delivery|store_pickup|transfer`) en Shipment → la bandeja muestra solo `store_pickup` (filtro en
  el teléfono, la lista se comparte con Recepción; si no viene el campo no filtra); `label_id` en
  `UnitTracking` → código de etiqueta real; `order_reference`/`customer_name` en `Delivery` → carga del
  camión. Al regenerar, `deliveryMode` saldrá como enum: ajustar `_customerPickups`
  (`counter_pickup_screen.dart`). No habrá `fulfillment_type`.
- **1c HOY NO FUNCIONA:** el POD sin vehículo responde "no hay entrega abierta para el envío". El backend
  lo va a habilitar para rol tienda + `store_pickup` de su nodo, sin cambiar lo que manda la app. Hasta
  entonces "Registrar entrega" en tienda es RECHAZADO.
- **Aviso al cliente:** lo dispara la **conciliación de la recepción** en la tienda
  (`execution.node_reception_reconciled`), NO un POD del chofer (eso lo marcaría entregado al cliente). El
  flujo de la app no cambia: chofer descarga, tienda recibe y concilia.
- Pendiente backend: `ready_for_pickup_at` + filtro, `q`, 1c, cliente/nodo en resolve, aviso, filtro
  `status` en entregas del vehículo, `route_id` en odómetro + 409 (lo de `DriverRoute.id` por salida aún
  sin confirmar). QR de retiro: anotado, no ahora.

**Backend implementó (2º aviso, 2026-11-14; working tree SIN commit ni deploy, spec actualizado):**
`q=` y `ready_for_pickup=true` en GET /app/shipments + `progress.ready_for_pickup_at`; POD de mostrador
para rol tienda (abre y cierra la entrega, `vehicle_id: ""`; no probado con token real de tienda);
cliente + `destination_node_id` en `/labels/{id}/resolve` (la app YA los lee: `LabelResolution` es a
mano); aviso al cliente al conciliar (solo nº de pedido; productos/tienda/horario = plantilla que edita el
dueño en el admin; solo si hay email o teléfono); `open=true` / `status=` en
GET /app/vehicles/{id}/deliveries; `route_id` en odómetro + 409 `route_already_closed`.
**Falta en la app tras REGENERAR el cliente:** usar `q` (búsqueda en servidor),
`delivery_mode=store_pickup&ready_for_pickup=true` en la bandeja, `open=true` en carga del camión y
mandar `route_id` en el odómetro de llegada.
**Decisión pendiente del DUEÑO:** el backend tiene UNA sola ruta por vehículo y por día; una segunda
salida el mismo día no existe (no hay otro `DriverRoute.id`). Sin "Rehacer", no hay forma de pedir una
segunda inspección el mismo día hasta que se decida soportar dos rutas diarias.

**Mejora futura anotada por el dueño (factible):** mandarle al cliente un **QR de retiro** en ese aviso;
la tienda lo escanea en vez de digitar el código (es lo mismo que digitar: lleva el código del pedido,
mejor firmado Ed25519 como las etiquetas). En la app solo habría que aceptar ese formato en "Escanear
etiqueta".

Ver [[product-ux-decisions]], [[pod-scanner-vehicle-hardening]], [[code128-label-scanning]].
