# Recojo en tienda (cliente retira), aviso al cliente, carga del camión y cierre de ruta

- **De:** app interna DisTrack (logistics-app)
- **Para:** backend logistics
- **Fecha:** 2026-11-14
- **Prioridad:** Alta (pedido directo del dueño). El punto 4 es **crítico** (honestidad de datos).

Pedido del dueño, en sus palabras: el usuario tienda tiene un recojo en tienda donde **un cliente real
va a recoger su pedido** (distinto del envío de almacén a tienda); se busca por **código del pedido**;
la entrega es **el mismo proceso del chofer** (escaneo de productos, firma del cliente, foto de entrega
obligatoria, foto del documento opcional) y al guardar **cambia el estado a entregado**. Cuando el chofer
entrega los productos en la tienda, el sistema debe registrar ese tracking y **avisarle al cliente** que
su pedido llegó y que pase a recogerlo.

La app solo consume el backend: no integra WhatsApp/SMS/correo. Todo aviso al cliente es del backend.

## Qué hizo ya la app (sin esperar al backend)

- **Recojo en tienda** (`/store/pickup`): buscador por código de pedido / cliente / documento (filtra lo
  ya cargado) y botón **Escanear etiqueta** que dice de qué pedido es y a qué cliente se entrega
  (QR: sale del contenido; Code128: `GET /app/labels/{labelId}/resolve`).
- **Entrega del recojo** (`/store/pickup/pod`): mismo flujo del chofer. Escanear productos NO entrega;
  al tocar "Registrar entrega" manda:
  - `POST /app/deliveries/evidence` con `kind: signature` (firma PNG) y, si hay, `kind: id_document`,
    ambas con `client_snapshot` (nombre, teléfono, documento, lat/lng, captured_at);
  - `POST /app/deliveries/photos` (`kind: pod`), foto obligatoria;
  - un `POST /app/deliveries/proof-of-delivery` **por cada producto** escaneado, con
    `confirmation: "FIRMA_DIGITAL"` y `photo_path` cuando la foto ya subió.
- Lista de productos del pedido con **nombre, SKU y código de etiqueta** (hoy el código es el `unit_id`
  abreviado, ver 1.d).
- **Carga del camión**: la app ya no muestra envíos entregados/fallidos y muestra cliente + nº de pedido
  tomándolos de la hoja de ruta (ver 4).

## 1. Recojo en tienda — lo que falta del backend

**a. Distinguir el tipo de envío.** Hoy `GET /app/shipments?destination_node_id=` devuelve TODO lo que
llega a la tienda: traslados de almacén a tienda y pedidos que un cliente retira, mezclados. La bandeja
"Recojo en tienda" debe listar solo los pedidos de **cliente que retira** y que ya están en la tienda.

Propuesta:

```yaml
# Shipment (aditivo)
fulfillment_type:
  type: string
  enum: [home_delivery, store_pickup, store_transfer]
ready_for_pickup_at:
  type: string
  format: date-time
  nullable: true   # cuándo quedó en tienda listo para retirar
# GET /app/shipments (filtros nuevos)
- name: fulfillment_type
  in: query
  schema: { type: string, enum: [home_delivery, store_pickup, store_transfer] }
- name: ready_for_pickup
  in: query
  schema: { type: boolean }
```

**b. Búsqueda en el servidor por código.** La app filtra solo las páginas ya cargadas (50 por página). Con
muchas páginas, un pedido puede no estar a la vista. Pedimos `GET /app/shipments?q=<texto>` (o
`external_id=`) que busque por código de pedido, nombre o documento del cliente dentro de la tienda.

**c. POD de mostrador → ENTREGADO.** Confirmar (o habilitar) que `POST /app/deliveries/proof-of-delivery`
funciona para un pedido `store_pickup` **sin vehículo ni ruta** (hoy el backend puede responder "no hay
entrega abierta para el envío"). Al registrarse el POD de todos los productos:
- el envío pasa a `DELIVERED` (tracking incluido) y sus etiquetas a "Entregada", igual que con el chofer;
- la evidencia (`signature`, `pod`, `id_document`) queda ligada y vuelve en `data.evidence` con `url`;
- el rol **tienda** tiene permiso para `evidence`, `photos` y `proof-of-delivery` de envíos de su nodo.

**d. Código de etiqueta por producto.** `GET /app/tracking/shipments/{id}/units` devuelve `unit_id`, `sku`,
`product_name`, pero no el **código impreso de la etiqueta** (el `label_id` del Code128). El personal lo
necesita para ubicar el producto en su almacén. Pedimos `label_id` (nullable) en `UnitTracking`.

**e. Etiqueta → pedido y cliente.** `GET /app/labels/{labelId}/resolve` ya devuelve `shipment_id`,
`order_number`, `sku`, `product_name`. Pedimos sumar `customer_name`, `customer_document_id`,
`customer_phone` y `destination_node_id`, para mostrar los datos del cliente aunque el pedido no esté en
las páginas cargadas, y saber si es de otra tienda.

## 2. Chofer entrega en tienda → tracking + aviso al cliente

Cuando el chofer entrega en la tienda los productos de un pedido `store_pickup` (escaneo de entrega en la
parada de la tienda / recepción conciliada por la tienda), el backend debe:

1. Registrar el hito de tracking: de "en camión" a **"Entregado en tienda — listo para retirar"**
   (`ready_for_pickup_at`).
2. Disparar **una acción en el servidor** que avise al cliente por el medio de contacto que tengamos
   (teléfono/WhatsApp/SMS/correo): que su pedido llegó, **nº de pedido**, **productos**, tienda y horario.
   Idempotente (un aviso por pedido, aunque se reintente el escaneo).

La app no envía nada: solo hace los escaneos que ya hace. Pedimos confirmar **qué evento** lo dispara
(POD del chofer en la parada de la tienda, o la conciliación de la recepción) para que la app no tenga
que cambiar el flujo.

## 3. Mejora futura: QR de retiro (anotado, no bloquea)

Sería ideal mandarle al cliente, en ese aviso, un **QR de retiro**. En la tienda el personal lo escanea
en vez de digitar el código. Es factible y es lo mismo que digitar: el QR lleva el código del pedido
(mejor firmado, con el mismo esquema Ed25519 de las etiquetas, para que la app lo valide sin red). La app
ya tiene el buscador y el escáner; cuando exista el QR solo hay que aceptar ese formato en el botón
"Escanear etiqueta".

## 4. 🔴 Carga del camión — datos honestos

En "Cargar al camión" aparecían envíos **ya entregados** y se listaban como "Envío 1, 2, 3". La app ya lo
corrigió de su lado (filtra por estado de la entrega y de la parada; muestra cliente y pedido de la hoja
de ruta), pero el dato debe venir bien del backend:

- la lista de entregas del vehículo para carga debe **excluir** las `delivered` / `failed`
  (o aceptar `?status=pending,prepared,loaded`);
- cada `Delivery` debe traer `order_reference`, `customer_name` y `units_total` / `units_loaded`
  (hoy solo trae `shipment_id` y los escaneos).

## 5. Cierre de ruta y checklist por ruta

- **Odómetro de llegada:** la app oculta "Cerrar ruta del día" cuando ya hay una lectura `arrival`
  posterior a la última `departure` del día. Es una inferencia por hora. Pedimos `route_id` (opcional) en
  `POST` y `GET` de lecturas de odómetro, y que el backend **rechace (409)** una segunda `arrival` para la
  misma ruta.
- **Checklist por ruta:** se quitó el botón "Rehacer"; la app pide la inspección cuando la ruta en curso no
  tiene una con su `route_id`. Confirmar que **cada nueva salida** (segunda ruta del día) tiene un
  `DriverRoute.id` distinto, que es lo que dispara el pedido de una nueva inspección.

## Criterio de aceptación

1. La bandeja de recojos de una tienda solo trae pedidos `store_pickup` listos para retirar, y se puede
   buscar por código en el servidor.
2. Registrar la entrega de un recojo desde el rol tienda deja el pedido `DELIVERED`, con firma, foto y
   documento visibles en `data.evidence`.
3. Al llegar el pedido a la tienda el cliente recibe **un** aviso con nº de pedido y productos.
4. La lista de carga del vehículo no trae entregados y trae cliente y nº de pedido.
5. Todo queda en `openapi/v1.yaml`.
