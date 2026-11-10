# Pedido al backend — Etiquetado por orden (simple), multishipping n-a-n y preview

Fecha: 2026-11-05 · App: logistics-app (Flutter) · Origen: visión del dueño sobre "Emitir etiquetas".

## Objetivo (del dueño)

El punto del etiquetado es que **todo ya esté autorizado** y **optimizar tiempos sin errores de
almacén**. Cada orden/solicitud de despacho **ya tiene su origen y destino**, y **cada producto sabe a
qué tienda / domicilio / almacén va**. Entonces la pantalla de etiquetas debe ser SIMPLE: una **lista de
productos** (nombre, SKU y **foto**) con un **botón por producto** para generar e imprimir su etiqueta.
Hoy la app pide cargar Origen/Destino/SKU/Nombre a mano (ver captura) — eso hay que eliminarlo: los datos
salen de la orden.

También: **ver órdenes multishipping** → una misma orden con **varios envíos** (un producto a un
domicilio, otro a otra dirección, otro a una tienda/almacén): combinación **n-a-n** producto→destino.

## Lo que hoy existe (para contexto)

- `GET/POST /app/orders/{orderNumber}/labels` (LabelCollection de `EmittedLabel`): cada etiqueta trae
  `sku`, `line_number`, `qr_content` (firmado), `zpl`, `emitted_at`, `revoked`. **No** trae nombre de
  producto, foto, origen ni destino.
- `EmitLabelsRequest` exige `origin`, `destination`, `lines` (carga manual) — lo que queremos evitar.
- El detalle del envío (`GET /app/shipments/{id}`) sí trae líneas con `product_name`, `sku`, `image_url`,
  `quantity` — la app ya puede mostrar foto/nombre/SKU desde ahí, PERO sin el destino por producto.

## Lo que necesita la app (contrato)

### 1. Vista de etiquetado de la orden (lo central)

Un endpoint que, dado un pedido, devuelva **las líneas a etiquetar ya resueltas y autorizadas**, sin
que la app arme nada a mano. Propuesta:

`GET /app/orders/{orderNumber}/dispatch-lines` → por cada línea/unidad a etiquetar:

- `sku`, `product_name`, `image_url` (foto del producto), `quantity`, `pieces_per_unit`
- `line_number` (para casar con `EmittedLabel.line_number`)
- **`origin`**: `{ type: 'store'|'warehouse'|'node', name }` (nombre humano, NO uuid)
- **`destination`**: `{ type: 'home'|'store'|'warehouse', name, address? }` (nombre/dirección humana, NO uuid)
- `shipment_reference` (código legible del envío al que pertenece la línea)
- `authorized` (bool) y, si aplica, `label_status`: `pending` | `emitted` | `revoked`

**Multishipping (n-a-n):** líneas de la MISMA orden pueden tener **distinto `destination`** (y hasta
distinto `origin`). La respuesta debe permitir agrupar por envío/destino (p. ej. incluir `shipment_id`
+ `shipment_reference` + `destination` por línea) para que la app muestre "este producto → domicilio X,
este otro → tienda Y". Si ya hay un modelo de envíos hijos por vendedor/destino, exponelo acá.

### 2. Enriquecer `EmittedLabel` (para la lista y el preview sin ids)

Agregar a cada `EmittedLabel`: `product_name`, `image_url`, `origin` y `destination` (mismos shapes que
arriba, nombres humanos). Así la lista de etiquetas emitidas y el preview muestran datos, no uuids.

### 3. Preview de la etiqueta (para ver/imprimir desde la app)

El dueño quiere **previsualizar la etiqueta** antes de imprimir (o solo verla). Dos opciones (preferimos A):

- **A (preferida):** una imagen renderizada de la etiqueta. Un campo `preview_png_url` (o
  `preview_png_base64`) en `EmittedLabel`, o `GET /app/labels/{labelId}/preview.png`. Es el preview más
  fiel (lo que sale por la Zebra).
- **B (fallback):** datos estructurados suficientes para que la app dibuje un preview aproximado: ya
  tenemos `qr_content` (renderizamos el QR) + necesitamos `product_name`, `sku`, `quantity`,
  `destination`, `shipment_reference` legibles (los del punto 2). La app dibuja la etiqueta.

Si B es lo viable ahora, la app arranca con el preview propio; cuando exista A lo cambiamos por la imagen
real. Decime cuál pueden dar.

### 4. Autorización

Confirmar que el etiquetado solo liste **líneas autorizadas** (orden/plan publicado). Si una línea no
está autorizada, que venga con `authorized: false` + motivo, para que la app no ofrezca imprimirla.

## Encargo explícito del dueño al backend

> "Dale el encargado al backend que pueden ver órdenes multishipping, es decir una orden con varios
> envíos en la misma orden (ej: un producto a un domicilio, otro a otro y otro a tiendas): combinación
> n-a-n. Trabaja de la mano con el backend."

Es decir: el **modelo de orden multishipping (n-a-n producto→destino)** y su exposición en el endpoint de
etiquetado es responsabilidad del backend; la app consume y muestra.

## Del lado app (en paralelo, ya en curso)

- Rediseño de "Emitir etiquetas" a **lista de productos** (foto + nombre + SKU + cantidad) con botón por
  producto para emitir/imprimir, usando por ahora las líneas del detalle del envío.
- **Preview de etiqueta** en la app (opción B: QR desde `qr_content` + datos del producto) hasta tener la
  imagen renderizada (opción A).
- Cuando entreguen `dispatch-lines` + `EmittedLabel` enriquecido, cableamos origen/destino por producto y
  el agrupado multishipping, y regeneramos el cliente desde `openapi/v1.yaml`.

¿Qué de esto pueden tomar y en qué orden? Lo antes útil para la app: **(2) enriquecer EmittedLabel** y
**(1) dispatch-lines con destino por línea**.
