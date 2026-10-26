# Pedido al backend: tienda asignada al usuario del rol tienda

**De:** app interna (logistics-app) · **Para:** agente/equipo del repo `logistics` (backend)
**Fecha:** 2026-10-16 · **Prioridad:** alta (regla de negocio + seguridad)

## Qué necesita la app

Regla de negocio confirmada por el dueño del producto: **un usuario del rol tienda solo recibe
mercadería y entrega pedidos de SU tienda.** Hoy la app muestra un selector con todos los nodos de
`GET /app/network/nodes` porque el backend no le dice a qué tienda pertenece el usuario.

Hoy `GET /app/auth/me` (`AppMeResponse` → `AppUserProfile`) solo trae `id`, `name`, `email` y
`roles`. Falta el nodo asignado.

## Cambios pedidos

1. **Asignación usuario → nodo** en el modelo (si no existe): un usuario `tienda` pertenece a un
   nodo de tipo `store` (idealmente uno; si el negocio permite varios, una lista).
2. **Exponerlo en `GET /app/auth/me`**, por ejemplo en `AppUserProfile`:
   ```yaml
   node:            # nullable: null para roles sin tienda (chofer, supervisor...)
     $ref: '#/components/schemas/Node'   # id, code, name, type, ...
   ```
   (o `nodes: [Node]` si puede tener varias). Que sea `nullable` para no romper otros roles.
3. **Autorización en el servidor** (lo más importante, no confiar en la app): en los endpoints de
   tienda, rechazar con 403 (`insufficient_scope` o similar, RFC 7807) cuando el `nodeId` /
   `destinationNodeId` no es el nodo del usuario:
   - `POST /app/node-receptions` (abrir recepción)
   - `GET /app/node-receptions/{shipmentId}/{nodeId}`
   - `POST /app/node-receptions/units` y `POST /app/deliveries/scans/node-reception`
   - `POST /app/node-receptions/reconcile`
   - el POD de recojo en tienda y el listado de envíos para recojo (filtrar por el nodo del usuario).
4. **Actualizar `openapi/v1.yaml`** con el campo nuevo para que la app regenere su cliente
   (regla #5 de la app: no se escriben DTOs a mano).

## Qué hace la app cuando esté listo

- Copia el `openapi/v1.yaml` nuevo, regenera el cliente y lee `me.user.node`.
- Rol tienda: **sin selector**; la tienda queda fija con la del usuario (nombre visible, no editable).
- Si `node` viene `null` para un usuario tienda: muestra "Tu usuario no tiene tienda asignada,
  contactá a tu supervisor" en lugar de dejar elegir.

## Otros cambios ya hechos en la app (solo informativo)

- "Entrega en mostrador" pasó a llamarse **"Recojo en tienda"** en la UI.
- Offline invisible: la app ya no muestra al usuario estados "sin conexión"/"pendiente"; la cola
  sigue igual (idempotente) y sube todo por debajo.
- Sesión persistente: el token + copia de la sesión quedan en el almacén seguro hasta logout o 401.
  Un token revocado se detecta en el primer request (401 → logout), así que conviene que el backend
  siga devolviendo 401 al revocar/expirar tokens de `/app/*`.
