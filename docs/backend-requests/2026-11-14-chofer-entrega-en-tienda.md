# Chofer entrega en tienda ≠ cliente retira en tienda (dos flujos distintos)

- **De:** app interna DisTrack (logistics-app)
- **Para:** backend logistics
- **Fecha:** 2026-11-14
- **Prioridad:** Alta. **Decisión del dueño**, corrige el punto 2 del pedido
  [recojo-en-tienda-aviso-cliente-carga](2026-11-14-recojo-en-tienda-aviso-cliente-carga.md).

## Decisión del dueño (textual, resumida)

Son **dos cosas distintas**:

1. **El camión deja el pedido en la tienda.** El centro de distribución lo envía a la tienda; el
   **chofer escanea los productos y saca una foto de entrega**. Nada más: sin firma, sin documento.
   Ese escaneo **es el pase a la tienda** ("entregado en tienda") y **en ese momento se notifica al
   cliente** que su pedido llegó.
2. **El cliente retira en la tienda** (flujo posterior). Ahí sí es como la entrega del chofer a domicilio:
   productos, **firma**, **foto de entrega** y **foto del documento opcional**. Ya está hecho en la app
   (rol tienda, `/store/pickup/pod`).

Esto cambia lo que respondiste: el aviso al cliente **no** lo dispara la conciliación de la recepción en
la tienda sino **la entrega del chofer en la tienda**.

## Qué pasa hoy en la app

En una parada el chofer solo tiene "Entregar" (POD: productos + firma del cliente + foto) y "No se pudo".
El POD deja el pedido **entregado al cliente**, que en una parada de tienda es falso. El escaneo de
descarga (`POST /app/deliveries/scans/unload`) existe pero su botón se quitó por obsoleto. La app **no
sabe** si una parada es una tienda o un cliente: `DriverRouteStop` no lo dice.

## Qué necesita la app

**a. Saber qué tipo de parada es.** En `DriverRouteStop` (aditivo):

```yaml
delivery_mode:
  type: string
  enum: [home_delivery, store_pickup, transfer]
destination_node_id: { type: string, format: uuid, nullable: true }
destination_node_name: { type: string, nullable: true }   # "Tienda Santa Cruz Norte"
```

Con `store_pickup` o `transfer` la app muestra "Entregar en tienda" (escaneo + foto) en vez de "Entregar".

**b. Una forma de cerrar la parada "entregado en tienda".** Lo que la app puede mandar hoy, sin endpoints
nuevos: un `POST /app/deliveries/scans/unload` por producto (con `node_id`) + `POST /app/deliveries/photos`
(`kind: pod`). Falta que eso **cierre la parada** sin POD de cliente. Dos opciones, elegí la que cuadre con
tu modelo y decime el shape exacto:

- que el `unload` del **último producto** de un envío `store_pickup`/`transfer` en su nodo destino cierre la
  parada (como hace el POD con el último producto), exigiendo que exista la foto; o
- un cierre explícito, p. ej. `POST /app/deliveries/{shipmentId}/store-drop` `{ node_id, photo_path?, lat,
  lng, occurred_at }`, idempotente.

**c. Efecto en el servidor al cerrar esa parada:**
- la parada del chofer queda **completada** (`completed_stops` la cuenta, item por item);
- el envío **NO** pasa a `DELIVERED`: queda "en tienda, listo para retirar" (`progress.ready_for_pickup_at`
  con la hora de la entrega del chofer) y sale en la bandeja `ready_for_pickup=true` de esa tienda;
- se dispara **el aviso al cliente** (una vez por pedido), si es `store_pickup`. Para `transfer` (stock de
  la tienda, sin cliente) no hay aviso;
- las etiquetas de esos productos pasan a un estado visible tipo "En tienda" (no "Entregada").

**d. ¿Qué queda de la "Recepción de mercadería" de la tienda?** Hoy la tienda abre la recepción, escanea
cada producto y concilia faltantes/sobrantes. Con el chofer marcando la entrega, decinos cómo conviven: la
propuesta de la app es que la recepción siga existiendo como **control de la tienda** (faltantes/sobrantes)
pero **sin** ser lo que dispara el aviso ni el "listo para retirar". Si un producto no fue escaneado por el
chofer, la tienda no debería poder entregarlo al cliente hasta recibirlo.

## Criterio de aceptación

1. Una parada de tienda se distingue en la hoja de ruta.
2. El chofer la cierra con escaneo de productos + foto, sin firma, y la parada cuenta como completada.
3. El pedido queda "listo para retirar" (no entregado) y el cliente recibe un aviso.
4. El retiro del cliente en la tienda (POD de mostrador) es lo único que lo deja `DELIVERED`.
5. Todo en `openapi/v1.yaml`.
