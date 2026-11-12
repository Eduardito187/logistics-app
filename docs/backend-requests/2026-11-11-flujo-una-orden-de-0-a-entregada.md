# Encomienda al backend — flujo COMPLETO de UNA orden, de 0 a entregada

Fecha: 2026-11-11 · Prioridad: ALTA (bloquea demos end-to-end y QA de terreno).

## Problema

Hoy **no se puede seguir UNA sola orden** por toda su vida (crear → etiquetar →
cargar → rutear → entregar) ni en la app ni por API con el acceso del app:

- Una orden con **0 etiquetas** (para mostrar la emisión/creación) **no está
  cargada** en un camión → el chofer no la puede entregar.
- Una orden en la **ruta activa** del chofer **ya tiene etiquetas** y está
  LOADED → no se puede mostrar su "creación desde 0".
- **Crear una orden** nueva requiere `POST /integrations/shipments` con
  `X-Service-Credential` (gate de integraciones), credencial que la app NO tiene
  y que no se debe exponer en el cliente.
- **Cerrar la entrega** por API (`POST /app/deliveries/proof-of-delivery`)
  responde **500** (ver doc `2026-11-11-asignacion-vehiculo-y-pod-validaciones.md`).

Resultado: las capturas/demos terminan mezclando órdenes distintas (el preparador
muestra `SCZ-2610xx` y el chofer `SCZ-2611xx`), que es justo lo que NO se quiere.

## Lo que se pide (para que exista el flujo de 0 a entregada)

### 1. Un endpoint de DEMO/QA que arme UNA orden coherente end-to-end
Idealmente un comando/endpoint (gate `/app/*` con rol admin/supervisor, o un
seeder invocable) que, dado un `order_number`, deje **la MISMA orden** disponible
en TODOS los pasos a la vez, para una cuenta de demo:
- en la **worklist del preparador** (estado PLANNED, **0 etiquetas** → se puede
  emitir),
- asignable a un **vehículo real**,
- y, tras emitir+cargar, **en la ruta activa del chofer** de ese vehículo
  (`Entrega en curso`), lista para POD.

Sin esto, ninguna demo puede mostrar la cadena real de una orden.

### 2. Asignación de vehículo que ATE la orden a la ruta
`POST /app/orders/{orderNumber}/vehicle { vehicle_id }` (gate `/app/*`): valida
que el vehículo existe/está operativo (422 si no), y **pone la orden en la ruta de
ese vehículo**. Hoy "Asignar vehículo" es estado LOCAL del app; el tracking no se
liga de verdad. (Detalle en el doc de asignación/POD.)

### 3. POD: 500 → 422 y secuencia documentada
`POST /app/deliveries/proof-of-delivery` debe:
- devolver **422 con `detail`** cuando falta una precondición (no 500),
- documentar la **secuencia exacta** requerida (PREPARATION → LOAD → ¿arribo? →
  POD) y qué campos son obligatorios.
- **La FOTO de entrega es OBLIGATORIA SIEMPRE** (sin excepción de QA/test): toda
  entrega se cierra con foto. `photo_path` debe ser requerido para cerrar; si
  falta, **422** (no 500). No se pide ningún modo de cierre sin foto.

### 4. `route` y `deliveries` del vehículo deben coincidir
`/app/vehicles/{id}/route` (paradas de hoy, `SCZ-2611xx`) y
`/app/vehicles/{id}/deliveries` (`SCZ-2610xx`…) devuelven conjuntos distintos; el
`shipment_id` de la parada de hoy **no se encuentra** por `/deliveries`. Que
compartan `shipment_id` (o exponer el vínculo) para validar y cerrar la parada
correcta. Idealmente la parada incluye sus `unit_ids` esperados (validación
offline del bulto escaneado).

### 5. Confirmar el modelo de "confirmación del cliente"
En reparto a domicilio se quitó "Escanear QR del cliente" (el cliente no tiene un
código): confirma firmando. **Pregunta:** ¿recojo en tienda / transportista usan
un **código de recojo** legítimo? Si no, se quita de esas pantallas también.
(`ProofOfDeliveryRequest.confirmation` dice "QR del cliente o firma".)

## Nota de alcance (app)

La app ya hizo su parte client-side: emisión por orden sin form, reimpresión solo
con motivo, **selector de vehículos reales** (`/app/fleet/vehicles`), validación de
que el bulto escaneado pertenece al envío, escáner con manejo de error, y quitó el
"QR del cliente" en reparto. Lo que falta para el flujo de 0 a entregada es
backend: puntos 1–4.
