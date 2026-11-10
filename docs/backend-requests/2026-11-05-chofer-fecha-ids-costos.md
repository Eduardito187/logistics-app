# Pedidos al backend — vista chofer (fecha, IDs/referencias, costos)

Fecha: 2026-11-05 · App: logistics-app (Flutter) · Origen: feedback del dueño probando la app.

La app ya aplicó mitigaciones del lado cliente; igual conviene corregir en el backend
para no depender de parches en el cliente generado.

## 1. "Armar ruta del día" → 422 "The route_date field must match the format Y-m-d"

- **Endpoint:** `POST /app/vehicles/{vehicleId}/route` (assembleDailyRoute), campo **`route_date`** en el body.
- **Causa:** el cliente generado (retrofit) serializa `DateTime` como `2026-11-05T00:00:00.000`;
  Laravel valida `route_date` como `date_format:Y-m-d` y lo rechaza.
- **Mitigación en el cliente (ya hecha):** el interceptor `DateQueryInterceptor` ahora recorta las
  fechas de calendario a `Y-m-d` también en el **body** (antes solo en el query).
- **Pedido al backend (ideal):** en el OpenAPI, tipar `route_date` (y cualquier fecha de calendario de
  los request bodies) como `type: string, format: date` para que el contrato sea coherente; o aceptar
  ISO-8601 además de `Y-m-d`.

## 2. No mostrar IDs/UUID en la UI — faltan referencias legibles

Regla del dueño: **el chofer/usuario nunca debe ver un uuid; se muestran datos, no ids.** Hay endpoints
que solo devuelven ids, así que la app no tiene qué mostrar y caía al uuid.

- **`GET /app/vehicles/{vehicleId}/deliveries`** (listVehicleDeliveries → `Delivery`): hoy solo trae
  `id`, `shipment_id`, `vehicle_id`, `status`, POD y scans. **Agregar** una referencia humana del envío:
  nº/código de pedido, nombre del cliente o `external_id`. (Mitigación cliente: se muestra "Envío N" por
  orden de lista.)
- **Objetos de vehículo**: asegurar que siempre venga `plate` (placa). Si un vehículo no tiene placa,
  igual la app evita mostrar el uuid (muestra "Vehículo asignado").
- En general, cualquier payload que la app muestre debería traer el nombre/código junto al id.

## 3. "Costos (últimos 30 días)" no muestra nada

- **Endpoint:** `GET /app/vehicles/{vehicleId}/cost-summary` (vehicleCostSummary → `VehicleCostSummary`).
- **Síntoma:** la sección de costos del "Resumen del vehículo" aparece vacía.
- **A verificar en el backend:** que el endpoint devuelva datos reales para el vehículo del chofer de
  prueba (TCO, costo/km, combustible, mantenimiento, otros, km). Si está devolviendo todo en cero o un
  payload vacío, la UI se ve "sin nada". Confirmar que hay datos sembrados para el escenario de prueba.

## 5. "Armar ruta del día" → 422 "The stop field is required" (y por eso "Mi ruta" no trae estados)

- **Endpoint:** `POST /app/vehicles/{vehicleId}/route` (assembleDailyRoute).
- **Síntoma 1 (en el log):** la validación responde **`The stop field is required`** (campo singular
  `stop`). El body que manda la app es `{ "route_date": "Y-m-d", "stops": [] }`: la app **no** arma
  paradas manuales porque el contrato dice que **el backend ensambla desde el plan publicado** (ver
  descripción del propio endpoint en el OpenAPI: "Assemble the driver route of the day from the published
  plan stops"). Es decir, el backend **pide** un campo que el cliente no debe llenar.
- **Síntoma 2 (consecuencia):** como el ensamblado falla con 422, la ruta nunca se crea, así que
  `GET /app/vehicles/{vehicleId}/route` vuelve sin paradas y **"Mi ruta" no muestra ningún estado de
  entrega** (lista vacía / "Sin paradas"). No es un bug de la UI: la UI ya mapea PENDING/COMPLETED/FAILED
  (y un fallback para estados desconocidos); simplemente no llega ninguna parada.
- **Incoherencia de contrato:** el OpenAPI declara el body con `stops` (plural, `required`, lista de
  `{shipment_id, sequence, ...}`), pero el servidor valida un campo `stop` (singular). Nombres distintos
  + `required` sobre algo que el cliente no provee.
- **Pedido al backend (ideal):** que `POST /app/vehicles/{vehicleId}/route` **ensamble desde el plan
  publicado** y, por tanto, **`stops` sea opcional** (aceptar body sin `stops` o con `[]`). Si se quiere
  seguir aceptando paradas explícitas, que el campo se llame igual que en el OpenAPI (`stops`, plural) y
  no sea obligatorio. Tras el cambio, regeneramos el cliente y la app deja de mandar `stops: []`.
- **Mitigación en el cliente:** ninguna posible sin romper el contrato (el modelo generado marca `stops`
  como requerido). Queda bloqueado hasta el fix del backend.

## 4. Rastreo de ubicación — invisible para el chofer (recordatorio de contrato)

El rastreo del camión sigue activo pero **nada en la UI del chofer debe delatarlo** (es solo para
administradores). La app quitó la pantalla "Rastreo del camión" y la notificación pasó a un texto neutro.
El backend no necesita cambios por esto; queda anotado como contrato de producto.
