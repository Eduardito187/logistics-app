# Etiquetas de envío ENTREGADO siguen "Cargada": unit_id = label_id, reasignación recrea unidades, sin fila de tracking

**Fecha:** 2026-11-13 · **Pide:** app interna (chofer) · **Para:** backend `logistics`
**Prioridad:** 🔴 CRÍTICO. Reproducido con datos reales en staging tras el deploy + reconcile.

El dueño entregó el pedido **SCZ-261113-01** (2 colchones) hace un minuto; el envío quedó
`DELIVERED` pero el **ciclo de vida de las ETIQUETAS sigue en "Cargada"/"Reasignada"**, sin
"Entregada". El reconcile no lo recuperó. Diagnóstico con queries directas (staging DB `logistics`):

## Datos (SCZ-261113-01)

- **shipment** `01a1c719-8152-787d-ba31-c8ef410825df` → `status = DELIVERED`.
- **execution_deliveries** `01a1d3b6-de57-7cfd-b4fb-3e517df2b03f` → `status = DELIVERED`.
- **execution_scan_events** de esa entrega: **UN SOLO** `PROOF_OF_DELIVERY`, con
  `unit_id = 01M73HK0D0C8YB33Z48ADGXX9T`, `occurred_at = 03:03:39`.
- **labels_emitted**: 2 etiquetas del order `SCZ-261113-01`:
  - `01M73HK0D0C8YB33Z48ADGXX9T` (línea 1, COL-QUEEN-ORT)
  - `01M73HK0D0XHKQZVZQPNJ8WSKA` (línea 2, BAS-QUEEN)
- **shipment_units** reales del envío (UUID v7), creadas `03:04:05`:
  - `01a1c719-8152-7113-ac10-16a187915de1`
  - `01a1c719-8152-7647-aaa6-0e8aeb8bae1c`
- **tracking_shipments** de ese shipment: **0 filas** (no existe el read model de tracking).
- **label_events**: solo `reassigned` (904U10→131O17 a las 03:02:56; 131O17→904U10 a las 03:03:08,
  por "Preparador Demo") y `printed`. Ningún evento de entrega.

## Causas (desglosadas)

### 1. 🔴 `unit_id` del POD = LABEL_ID, no el `shipment_unit.id`
El scan `PROOF_OF_DELIVERY` trae `unit_id = 01M73HK0D0C8YB33Z48ADGXX9T`, que es el **label_id** de la
etiqueta 1 (un ULID), **no** un `shipment_units.id` (los reales son UUID v7
`01a1c719-8152-7113…` / `…7647…`). **Nunca matchean.**
- Por qué: el chofer ESCANEA la etiqueta; el valor del QR/Code128 es el `label_id` (el payload
  firmado `signed_json` NO trae `shipment_unit_id`), así que la app manda el label_id como unit_id.
- Efecto: la entrega a nivel envío avanzó (delivery DELIVERED), pero el **marcado por UNIDAD y el
  ciclo de la ETIQUETA** (que deriva "Entregada" de un POD ligado a la unidad) no encuentran la
  unidad → las etiquetas quedan "Cargada" aunque el envío esté entregado.
- **Pedido:** al procesar el POD, **resolver label_id → shipment_unit** (por `labels_emitted.order_id`
  + línea, o un índice label→unit), y/o que `LabelLifecycle` marque "Entregada" cuando exista un POD
  del order/línea de esa etiqueta (no exigiendo que `scan.unit_id == shipment_unit.id`). La app no
  puede mandar el UUID: no lo tiene (no está en el payload de la etiqueta); el chofer solo tiene el
  label_id que escanea.

### 2. 🔴 La REASIGNACIÓN recrea las shipment_units DESPUÉS del POD
Línea de tiempo: reasignación 03:02:56 y 03:03:08 → **POD 03:03:39** → **shipment_units creadas
03:04:05**. O sea el flujo de reasignación (Preparador Demo) **recreó las unidades con UUID nuevos
DESPUÉS** de registrarse el POD → cualquier scan previo queda huérfano. Es una condición de carrera /
orden: reasignar no debe recrear unidades que invaliden entregas ya hechas (o debe re-vincular los
scans/POD a las unidades nuevas).

### 3. 🔴 El reconcile NO recupera envíos SIN fila de tracking
`tracking_shipments` no tiene fila para este envío (0 filas). El `reconcile-from-execution` (que
corrí: 30 revisadas, 30 reproyectadas) hace JOIN con `tracking_shipments`, así que un envío **sin
fila** queda fuera y no se recupera. **Pedido:** que el reconcile (y la proyección) haga **UPSERT**
(cree la fila de tracking si falta), no solo UPDATE de las existentes. Por eso este envío no entró en
mi verificación "14 DELIVERED×DELIVERED".

### 4. (secundario) Solo 1 POD para 2 etiquetas
El order tiene 2 etiquetas/unidades pero hay **un solo** `PROOF_OF_DELIVERY`. Aun arreglando 1–3, la
etiqueta 2 (BAS-QUEEN) no tendría POD. ¿El POD debe cerrar TODAS las unidades del envío de una, o se
espera un scan por etiqueta? (La app hace un POD por unidad de `unitIds`; si `unitIds` no trae las 2,
o el chofer escaneó 1, queda 1.) Conviene definir: POD a nivel envío cierra todas sus unidades/etiquetas.

## Resumen para el backend
El envío está DELIVERED pero la etiqueta no, por un **desajuste label_id ↔ shipment_unit.id** (1), que
la **reasignación recreando unidades tras el POD** empeora (2), y que el **reconcile no cubre** porque
**falta la fila de tracking** (3). La app manda lo único que tiene (el label_id escaneado); la
resolución a unidad y el marcado de la etiqueta son del backend.
