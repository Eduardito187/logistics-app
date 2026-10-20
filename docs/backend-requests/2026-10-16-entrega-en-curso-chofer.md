# Pedido al backend: datos para la pantalla "Entrega en curso" del chofer

**De:** app interna (logistics-app) · **Para:** agente/equipo del repo `logistics` (backend)
**Fecha:** 2026-10-16 · **Prioridad:** alta (pantalla principal del chofer)

## Contexto

La app tiene una pantalla nueva para el chofer, estilo app de delivery: mapa a pantalla completa,
tarjeta de estado (parada N de M, hora estimada, progreso), hoja con los datos de la entrega
(cliente, teléfono, dirección) y el pedido (productos), botones del paso (escanear bultos, entregar
con foto obligatoria, no se pudo entregar) y "Ayuda" **sin chat** (llamar, navegar, reportar).

Hoy usa: `GET /app/vehicles/{vehicleId}/route` (parada actual, cliente, dirección, ETA, lat/lng),
`GET /app/shipments/{shipment}` (teléfono y líneas del pedido), `GET /app/deliveries/{shipmentId}`,
y los POST de descarga, POD y entrega fallida que ya existen.

## Lo que falta

1. **Permiso del chofer sobre `GET /app/shipments/{shipment}`.** La app lo usa para el teléfono del
   cliente y los productos. Confirmar que el rol chofer puede leerlo (solo los envíos de su ruta);
   si no, exponer esos datos en la parada (punto 2).
2. **Enriquecer `DriverRouteStop`** (evita una llamada por parada y funciona con la ruta cacheada):
   - `customer_phone` (string, nullable)
   - `address_reference` (indicaciones: portón, piso…), nullable
   - `items`: `[{ sku, name, quantity, image_url? }]`
3. **Foto del producto:** `image_url` (nullable) en las líneas del envío (`ShipmentLine`) y/o en
   `items` de la parada. La app ya reserva el lugar (56x56) y la mostrará apenas llegue.
4. **Ruta por calles para el chofer:** `DriverRoute` no trae geometría (solo `Plan.route_geometry`
   del módulo de planificación). Pedido: `route_geometry` (mismo esquema `RouteGeometry`, GeoJSON
   LineString `[lng, lat]`) en `DriverRoute` o al menos el tramo hacia la parada actual. Mientras no
   exista, la app dibuja una línea directa camión → destino.
5. **Reportar inconveniente de la entrega (sin fallarla):** hoy solo existen "entrega fallida"
   (`POST /app/deliveries/failed`, que cierra la entrega) e incidente de **vehículo**
   (`BREAKDOWN`/`ACCIDENT`). Falta un reporte que no cierre la entrega (demora, acceso restringido,
   el cliente pide esperar, dirección confusa…). Propuesta:
   `POST /app/deliveries/{shipmentId}/issues` con
   `{ type: DELAY|ACCESS|CUSTOMER_REQUEST|ADDRESS_UNCLEAR|OTHER, note?, lat?, lng?, occurred_at, photo_path? }`,
   idempotente (`Idempotency-Key`), y en `openapi/v1.yaml`. La app lo agregará en "Ayuda" →
   "Reportar un inconveniente" (y lo encolará offline como el resto).
6. **Foto obligatoria del POD:** la app ya no permite registrar la entrega sin foto. Si el backend
   quiere reforzarlo, puede exigir `photo_path`/`photo_url` en `ProofOfDeliveryRequest` para el rol
   chofer.

Todo cambio de contrato, por favor reflejarlo en `openapi/v1.yaml` para regenerar el cliente.
