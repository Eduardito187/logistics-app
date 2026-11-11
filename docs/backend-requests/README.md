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
| [emit-por-orden-deriva-origen-destino](2026-11-05-emit-por-orden-deriva-origen-destino.md) | **Entregado (working tree)** · pendiente commit | `POST /app/orders/{orderNumber}/labels` con body vacío → backend deriva origen (CD del departamento) + destino + líneas y emite autorizadas+pending (idempotente). App ya cableada (Dio crudo, sin form). Falta commit de `feature/commerce-fase0` (decisión del dueño) + regen opcional. |
| [ruta-parada-tipo-de-destino](2026-11-05-ruta-parada-tipo-de-destino.md) | **Delegado** sesión `logistics-8e` | `DriverRouteStop.destination.type` (home/store/warehouse) para mostrar una sola acción por parada (Entregar cliente vs Descargar hub/tienda). Derivable de `destination_node_id`. |
| [evidencia-ligada-al-cliente-antifraude](2026-11-05-evidencia-ligada-al-cliente-antifraude.md) | **Delegado (en curso)** sesión `logistics-8e` | Firmas y fotos de documento ligadas al CLIENTE + validación anti-fraude (hash/auditoría, `kind` `signature`/`id_document`, OCR carnet BO vs `document_id`, verificación de firma). Investigación open-source on-prem con agentes en paralelo. |
| [escaneo-code128-resolve-label](2026-11-10-escaneo-code128-resolve-label.md) | **Entregado (contrato)** · app cableada | Simbología configurable (QR/Code128/ambos). Backend: `GET /app/labels/{labelId}/resolve` (200 siempre, mirar `resolved`) + `revoked`/`order_number`. QR sigue offline Ed25519; Code128 = `label_id` sin firma → se resuelve ONLINE (anulada/sin señal → rechazo). App cableada con Dio crudo (`label_resolver.dart`) + `kLabelScanFormats=[qrCode,code128]` en todos los escaneos de etiqueta, sin regen. Falta confirmar contra dev + commit/push del backend. |
| [sesiones-una-por-plataforma-banco](2026-11-05-sesiones-una-por-plataforma-banco.md) | **Entregado (working tree)** · app cableada | Backend: máx 1 `web` + 1 `app`; deriva bucket de `device.platform` (+`device.client_kind` opcional); segundo dispositivo del mismo bucket → 401 `session_superseded` (RFC7807). App: interceptor muestra "Iniciaste sesión en otro dispositivo" por `code` (sin regen). Push silencioso de desalojo = extensión futura. Falta commit/push de la rama. |
| [device-cache-otro-usuario](2026-11-11-device-cache-otro-usuario.md) | **CRÍTICO · aplicado en backend local (sin commit/deploy)** · app con mitigación | Login de OTRO usuario en el mismo teléfono → 401 `device_revoked` por snapshot cacheado 30 s en `EnsureDeviceToken` que `bindDevice()` no invalida. Fix: `forgetDevice()` en `Device::saved` cuando cambia `user_id`/`revoked_*`. App reintenta 1 vez dentro de 35 s tras el login. |
| [registro-impresoras-por-nodo](2026-11-11-registro-impresoras-por-nodo.md) | **pendiente** | Catálogo de impresoras de red por nodo en el panel + `GET /app/printers` (host, puerto, lenguaje zpl). En redes con WiFi y cable separados el teléfono no puede descubrir la impresora; registrada una vez, la app la ofrece. |

## Convenciones

- Nombre: `AAAA-MM-DD-tema-corto.md`. Encabezado con **De / Para / Fecha / Prioridad**.
- Contenido: contexto, qué hace hoy la app, qué falta, propuesta de contrato (YAML) y criterio de
  aceptación. Pedir siempre que el cambio quede en `openapi/v1.yaml`.
- Al entregarse: actualizar la fila de esta tabla (no borrar el documento) y regenerar el cliente.
