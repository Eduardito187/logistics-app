# Pedidos al backend

Pedidos de la app interna al repo `logistics` (backend). No hay sesión del backend en esta máquina:
cada pedido es un documento acá y se le pasa al equipo/agente del backend. Lo entregado se
verifica contra `openapi/v1.yaml` del backend (`\\wsl.localhost\Ubuntu-22.04\dismac\logistics`) y se
consume regenerando el cliente (`docs/cliente-api.md`).

**Lista de trabajo vigente:** [`2026-10-16-pendientes-consolidados.md`](2026-10-16-pendientes-consolidados.md)
junta todo lo que sigue abierto de los pedidos anteriores más los nuevos.

Estado al 2026-10-16 (revisado contra el spec del backend):

| Documento | Estado | Detalle |
|---|---|---|
| [tienda-asignada-al-usuario](2026-10-16-tienda-asignada-al-usuario.md) | **Entregado** | `AppUserProfile.node` en login y `/app/auth/me` + 403 `EnsureStoreNodeScope`. La app lo consume (tienda fija). |
| [envios-filtrados-por-tienda](2026-10-16-envios-filtrados-por-tienda.md) | **Entregado (contrato)** · pendiente dato | `GET /app/shipments` filtra server-side por la tienda y `Shipment.destination_node_id` existe, pero el ingest/SAP no lo puebla → lista de tienda vacía. Sigue en consolidado #1. |
| [entrega-en-curso-chofer](2026-10-16-entrega-en-curso-chofer.md) | **Entregado** salvo 1 punto | Entregados: `DriverRouteStop.customer_phone/address_reference/items(image_url)`, `ShipmentLine.image_url`, `DriverRoute.route_geometry`, `POST /app/deliveries/{id}/issues`. Pendiente: foto obligatoria del POD server-side → consolidado #3. (El permiso sobre `GET /app/shipments/{id}` dejó de ser necesario: los datos vienen en la parada.) |
| [push-fcm-app-interna](2026-10-16-push-fcm-app-interna.md) | **Parcial** | Entregado: `PUT /app/devices/current/push-token` y capacidad `sendToDevice`. Pendiente: cablear push 1-a-1 a eventos reales y publicar a topics `role_*`/`node_*` → consolidado #2. |
| [version-minima-app](2026-10-16-version-minima-app.md) | **Pendiente** | El spec aún no tiene `X-Min-App-Version`, `426` ni `/app/meta`. La app ya envía `X-App-Version`/`X-App-Build` y reacciona si llega la cabecera. |
| [firma-cliente](2026-10-16-firma-cliente.md) | **Pendiente** | `kind` de `POST /app/deliveries/photos` sigue `pod \| damage` (sin `signature`); la app sube la firma como `pod` mientras tanto. |
| [pendientes-consolidados](2026-10-16-pendientes-consolidados.md) | **Pendiente** | 1) poblar `destination_node_id`; 2) push 1-a-1 + topics; 3) foto POD obligatoria; 4) nombrar schemas anónimos (`DataN`…); 5) endpoint de KPIs del día. |

## Convenciones

- Nombre: `AAAA-MM-DD-tema-corto.md`. Encabezado con **De / Para / Fecha / Prioridad**.
- Contenido: contexto, qué hace hoy la app, qué falta, propuesta de contrato (YAML) y criterio de
  aceptación. Pedir siempre que el cambio quede en `openapi/v1.yaml`.
- Al entregarse: actualizar la fila de esta tabla (no borrar el documento) y regenerar el cliente.
