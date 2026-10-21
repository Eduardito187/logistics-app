# Pedido al backend (seguimiento): listado de envíos filtrado por la tienda del usuario

**De:** app interna (logistics-app) · **Para:** agente/equipo del repo `logistics` (backend)
**Fecha:** 2026-10-16 · **Relacionado:** `2026-10-16-tienda-asignada-al-usuario.md` (ya entregado: `user.node` + 403)

## Estado

Gracias por lo entregado: la app ya consume `AppUserProfile.node` (lo lee en el login y en
`/app/auth/me`, lo persiste en la sesión) y el rol tienda ya **no puede elegir tienda**: usa la suya
fija. El 403 de `EnsureStoreNodeScope` cubre el resto.

## Qué falta

`GET /app/shipments` (lo usan "Recepción de mercadería" y "Recojo en tienda") devuelve todos los
envíos. El modelo `Shipment` no trae el nodo destino y el endpoint no tiene filtro por nodo, así que
**la app no puede filtrar**: un usuario de tienda ve envíos de otras tiendas (aunque al operar sobre
ellos recibe 403, la lista confunde y expone datos de otras tiendas).

## Pedido

1. Si el usuario es Tienda, que `GET /app/shipments` devuelva **solo** los envíos cuyo destino (o
   punto de recojo) es `users.node_id`. Server-side, sin depender de un parámetro de la app.
2. (Opcional, útil) exponer `destinationNodeId` en `Shipment` en `openapi/v1.yaml` para que la app
   pueda mostrarlo/validarlo.
3. Si el POD de recojo en tienda (el endpoint que usa `recordPod`) no está bajo
   `EnsureStoreNodeScope`, agregarlo también.
4. Actualizar `openapi/v1.yaml` si cambia el contrato.

## Nota para la app

La app no necesita cambios si solo cambia el filtrado del lado del servidor (1). Con (2) se
regenera el cliente desde `openapi/`.
