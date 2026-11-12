# Encomienda al backend — asignación de vehículo y validaciones de entrega

Fecha: 2026-11-11 · Origen: pruebas en staging con la app (preparador + chofer).

Tres cosas que la app NO puede resolver sola y necesitan backend. Prioridad alta
las dos primeras: hoy **se puede "cerrar" o asignar algo que no corresponde**.

---

## 1. Asignar el pedido a un vehículo que EXISTE y que de verdad lo ata a la ruta

**Hoy:** en el andén, "Asignar vehículo de reparto" era **texto libre** (se podía
escribir cualquier placa). La app ya lo limitó a **elegir de `/app/fleet/vehicles`**
(solo camiones reales), pero esa elección es **estado LOCAL de la app**: NO existe
endpoint que ligue el pedido/envío al vehículo. Resultado: el tracking "se iba" a
un camión que no era (o a ninguno).

**Pedido:**
- Endpoint para **asignar un envío a un vehículo**, p. ej.
  `POST /app/orders/{orderNumber}/vehicle` (o `/app/shipments/{id}/vehicle`) con
  `{ "vehicle_id": "<uuid>" }`.
  - Valida que el vehículo **existe** y está operativo (`available`/`in_service`);
    si no, **422** con mensaje claro (no 500).
  - Deja el envío en la **ruta/plan de ese vehículo** para que aparezca en
    `Mi ruta de hoy` del chofer de ese camión.
  - Idempotente; permite reasignar.
- Que el envío ya asignado devuelva su `vehicle_id`/placa en el detalle del pedido
  (`/app/orders/{orderNumber}/dispatch-lines` o el shipment), para precargar la
  selección y mostrar el estado real.

Sin esto, la app solo puede mostrar una etiqueta local de vehículo, no cambiar la
realidad del backend.

---

## 2. `POST /app/deliveries/proof-of-delivery` devuelve 500 (debería 422 con motivo)

**Síntoma:** al cerrar la entrega directo por la API (bulto LOADED, body válido
con `shipment_id`, `unit_id`, `lat/lng`, `occurred_at`, `confirmation`), responde
**500 `server_error`** "An unexpected error occurred". El mismo flujo desde la app
sí entrega, así que **falta una precondición** (¿scan de descarga/arribo previo?,
¿foto obligatoria server-side?, ¿orden de scans?).

**Pedido:**
- Documentar la **secuencia exacta** de escaneos/estados requerida antes del POD
  (PREPARATION → LOAD → ¿UNLOAD/arribo? → POD) y qué campos son obligatorios.
- Que una precondición faltante devuelva **422 con `detail`** (qué falta), nunca
  **500**. Un 500 no le dice nada al chofer y parece "se colgó".
- Confirmar si `photo_path`/`photo_url` es realmente opcional (el schema dice
  `nullable`, pero el 500 sugiere que no).

---

## 3. `Mi ruta de hoy` vs `/app/vehicles/{id}/deliveries` no coinciden → "cerrar un pedido que no corresponde"

**Síntoma:** la ruta del chofer (`/app/vehicles/{id}/route`) muestra paradas con
referencias `SCZ-2611xx-xx`, pero `/app/vehicles/{id}/deliveries` (y el detalle de
entrega) devuelven **otro conjunto** (`SCZ-2610xx-xx`…). El `shipment_id` de la
parada de hoy **no se encuentra** por `/deliveries`. Por eso, al validar o cerrar,
la app puede terminar operando sobre **un envío que no corresponde** a la parada.

**App ya mitigó:** el POD ahora valida que el bulto escaneado pertenezca al
`shipment_id` de la parada (usa `/app/.../units`); si es de otro pedido, lo
rechaza con aviso en vez de cerrar lo que no es.

**Pedido:**
- Que la **parada de la ruta** y su **registro de entrega** compartan el mismo
  `shipment_id` (o exponer el vínculo), para poder:
  - validar el bulto contra la parada correcta, y
  - cerrar exactamente ese envío.
- Idealmente, un `GET` de la parada que incluya sus `unit_ids` esperados, así la
  validación es offline-first y no depende de otro endpoint.

---

## 4. Confirmación del cliente: NO hay "QR del cliente" en reparto a domicilio

En la entrega del **chofer** se quitó el botón "Escanear QR del cliente": el cliente
a domicilio no tiene un código que mostrar; confirma **firmando** (o con foto).

**Pregunta al backend:** en **recojo en tienda** y **transportista externo** el
cliente/receptor ¿tiene un **código de recojo** legítimo para escanear? Si NO, se
quita también de esas pantallas. Si SÍ, dejamos esas y documentamos su formato.
(`ProofOfDeliveryRequest.confirmation` hoy dice "QR del cliente o firma".)
