# Emitir etiquetas POR ORDEN (sin form) — el backend deriva origen/destino

- **De:** app (logistics-app)
- **Para:** backend (logistics)
- **Fecha:** 2026-11-05
- **Prioridad:** Alta (bloquea el etiquetado por producto que pidió el dueño)
- **Estado:** Acordado y en curso en la sesión `logistics-8e` (rama `feature/commerce-fase0`).

## Contexto

La pantalla de etiquetado ya es la **lista de productos** (dispatch-lines), sin formulario manual
(requisito duro del dueño: "el origen y destino ya están en la orden; por cada producto se genera su
etiqueta; nada de cargar origen/destino/SKU a mano"). Pero `POST /app/orders/{orderNumber}/labels`
(`emitShipmentLabels`) todavía exige `origin` + `destination` (códigos de nodo) + `lines`, que la app NO
puede armar: en líneas `pending` el `origin.code` viene `""` y para **domicilio** no hay nodo destino.
Verificado con `SCZ-261019-01`: `destination.type=home`, `origin.code=""`, `authorized=true`,
`label_status=pending`.

## Qué hace hoy la app

Abre el form manual (`label_batch_sheet`) con Origen/Destino/Líneas/Agregar. Se elimina.

## Contrato acordado

1. **Body OPCIONAL** en `POST /app/orders/{orderNumber}/labels`. Si viene vacío (sin `origin`/
   `destination`/`lines`), el backend emite TODAS las líneas **AUTORIZADAS** y aún **PENDING** de la
   orden, iterando envíos (multishipping), derivando por envío:
   - `destination`: `destinationCode()` del envío (ya existe en `EloquentDispatchLinesReader`), o el
     marcador home/cliente para domicilio.
   - `origin`: **CD del departamento del envío** (nodo→department; para domicilio: CD más cercano por
     haversine usando `shipments.lat/lng`, que existen; fallback al prefijo de la referencia
     `SCZ/LPZ/CBB`, y si nada, un CD default por env). Un **resolver único y testeable**.
   - `lines`: líneas del envío (`sku`, `product_name`→`name`, `quantity`, `pieces_per_unit`).
2. **`origin` opcional como escape hatch**: si el body trae `origin`, se usa; si no, se deriva (A).
3. **Idempotente / parcial**: salta líneas ya emitidas y emite el resto; responde `201` con la colección
   completa. `409` solo si no hay nada nuevo que emitir.
4. **No autorizadas** (sin plan publicado): no se emiten (ya se reportan `pending` + motivo).
5. **Backward-compatible**: el body explícito (worker pre-emit, reprint) queda igual.
6. **openapi aditivo**: `EmitLabelsRequest.origin/destination/lines` → opcionales/nullable; documentar el
   "emit por orden deriva del plan/envío".

## Nota clave (desbloqueó la duda del backend)

El **valor** de `org` del QR **no es contrato con Flutter**: la app lee `org` del QR y solo verifica la
**firma Ed25519** sobre el mensaje canónico (`lib/core/labels/label_verifier.dart`,
`label_payload.dart`, `signed_label.dart`); nunca compara el valor de origin contra nada. El contrato es
el **formato** canónico (orden de campos/encoding), que no cambia. El backend elige la derivación de
origin libremente; mantenerla estable.

## Criterio de aceptación

`POST /app/orders/{orderNumber}/labels` con body vacío → `201` + `LabelCollection` con una etiqueta por
pieza de cada línea autorizada+pending de la orden, origen/destino derivados. La app emite sin form.

## Lado app (cuando esté mergeado + openapi actualizado)

Regen quirúrgico del cliente + cablear emit-por-orden (botón del pedido y por producto) + cerrar el
mapeo `label_id→unit_id` offline (ver [etiquetado-por-orden-multishipping-preview](2026-11-05-etiquetado-por-orden-multishipping-preview.md)).
