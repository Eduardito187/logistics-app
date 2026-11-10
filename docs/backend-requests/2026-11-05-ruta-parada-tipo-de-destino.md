# Tipo de destino por parada de la ruta (cliente vs hub/tienda)

- **De:** app (logistics-app) — por pedido del dueño
- **Para:** backend (logistics)
- **Fecha:** 2026-11-05
- **Prioridad:** Media-alta
- **Estado:** Delegado al backend.

## Objetivo

En "Entrega en curso" (chofer) la acción debe depender del DESTINO de la parada, para mostrar UNA sola
acción (menos opciones = menos errores):
- **Cliente final (domicilio):** acción **"Entregar"** → POD (escanea el producto + foto obligatoria +
  firma).
- **Hub / tienda / almacén (nodo):** acción **"Descargar"/"Escanear"** → escaneo de descarga de los
  bultos (ScanMode.unload), sin foto/firma de cliente.

Hoy el chofer ve ambos botones (confusos) porque la app NO sabe el tipo de destino de cada parada.

## Qué falta en el contrato

`DriverRouteStop` (en `DriverRoute`, `GET /app/routes/...` / entrega en curso) NO expone el tipo de
destino. Tiene `customer_name`, `address`, `lat/lng`, `items`, etc., pero nada que diga si la parada es a
un **cliente** (domicilio) o a un **nodo** (tienda/almacén/hub).

## Propuesta de contrato (aditivo, openapi)

Agregar a `DriverRouteStop` un objeto `destination` (misma forma que `DispatchDestination` de
dispatch-lines, para reusar):

```yaml
destination:
  type: object
  required: [type]
  properties:
    type: { type: string, enum: [home, store, warehouse], description: "home = cliente/domicilio; store/warehouse = nodo (hub/tienda/almacén)" }
    name: { type: string, nullable: true, description: "nombre del nodo (si store/warehouse)" }
    node_code: { type: string, nullable: true }
```

Derivable de `shipments.destination_node_id` (si está seteado → store/warehouse según el nodo; si null →
home). Es el mismo dato que ya resuelve `EloquentDispatchLinesReader.resolveDestination/destinationCode`.

## Lado app (cuando esté)

- Parada `home` → botón **"Entregar"** (POD, como hoy).
- Parada `store`/`warehouse` → botón **"Descargar en {nombre}"** (escaneo de descarga, sin POD de
  cliente).
- "No se pudo" en ambos casos.
- Hoy (sin el campo) la app muestra solo **"Entregar"** (correcto para entregas a cliente; se quitó el
  "Escanear" suelto que era redundante).

## Criterio de aceptación

`DriverRouteStop.destination.type` presente en el contrato → la app muestra la acción que corresponde al
tipo de destino, una sola por parada.
