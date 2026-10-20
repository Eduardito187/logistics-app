---
name: product-ux-decisions
description: "Decisiones de UX del dueño (2026-10-16): offline invisible, campana de notificaciones en header, tienda fija, \"Recojo en tienda\", sesión persistente"
metadata:
  node_type: memory
  type: project
  originSessionId: 22a12647-3b3a-43c2-a3c3-8f46fc627148
  modified: 2026-10-16T07:11:59.708Z
---

Decisiones del usuario (dueño del producto) del 2026-10-16:

1. **Offline invisible.** El usuario de campo NUNCA debe saber que está sin conexión ("para evitar malos entendidos o malas intenciones"). Encolado se informa igual que enviado ("Registrado.", pastilla "Enviado"); `ApiException.message` sin red = "No se pudo completar. Intentá de nuevo en un momento."; sin nube/badge de sync en AppBars ni sección en Ajustes. Lo ÚNICO visible: snack "Sincronizando..." al volver la señal con pendientes (listener en `app.dart`, `OfflineQueue.pendingCount()`). La pantalla `/sync` sigue existiendo pero sin acceso desde la UI. Excepción inevitable: el login necesita red y avisa "No se pudo conectar con el servidor" + "Reintentar".
2. **Notificaciones:** solo la campana (`NotificationsButton`) en el header del inicio, todos los roles; sin tarjeta en el inicio.
3. **Rol tienda:** solo recibe/entrega en SU tienda, sin selector. HECHO 2026-10-16: el backend agregó `AppUserProfile.node` (login + `/app/auth/me`) y 403 (`EnsureStoreNodeScope`); la app guarda `Session.storeNode` (persistido en `app_session`), `selectedStoreNodeProvider` deriva de la sesión y `StoreSelector` es una tarjeta fija "Tu tienda". PENDIENTE backend: filtrar `GET /app/shipments` por la tienda del usuario (`docs/backend-requests/2026-10-16-envios-filtrados-por-tienda.md`).
4. "Entrega en mostrador" → **"Recojo en tienda"** en la UI.
5. **Sesión persistente tipo WhatsApp:** `SessionNotifier.restore()` en `main()` antes de `runApp` lee token + `app_session` (JSON nombre/rol/abilities) del secure storage; se borra solo en logout o 401.

6. **Push = Firebase Cloud Messaging** (2026-10-16). El canal push anterior se eliminó por completo; no volver a mencionarlo en el proyecto. Listo para "solo poner credenciales": `FIREBASE_API_KEY/APP_ID/MESSAGING_SENDER_ID/PROJECT_ID` en `config/*.json` → `firebase_options.dart` (sin google-services.json ni plugin Gradle). Sin credenciales: estado "No disponible". Se usa la API vigente de firebase_messaging 17 (`register()`/`onRegistered` → FID; `getToken`/`onTokenRefresh`/`deleteToken` están deprecados) y el FID viaja como `device.push_token` en el login. El backend hoy solo publica a topics `shipment_<id>`; pedido de envío directo + endpoint de actualizar token en `docs/backend-requests/2026-10-16-push-fcm-app-interna.md`. Guía: `docs/push-fcm.md`.

7. **Chofer: "Entrega en curso" estilo app de delivery** (2026-10-16, ruta `/driver/delivery`, tarjeta principal del inicio). Mapa a pantalla completa + tarjeta de estado (parada N de M, hora estimada, progreso en tramos) + hoja deslizable (cliente, teléfono con Llamar, dirección con Navegar, pedido con nombre/SKU/cantidad) + botones del paso (Entregar pedido / Escanear bultos / No se pudo; cerrada → Siguiente entrega). "Ayuda" SIN chat: llamar, navegar, escanear, no se pudo entregar, problema del vehículo, ver ruta. **La foto del POD es obligatoria.** Faltan del backend: ruta por calles para el chofer, foto de producto, reporte de inconveniente que no cierre la entrega, teléfono/ítems en la parada (`docs/backend-requests/2026-10-16-entrega-en-curso-chofer.md`).

8. **Backend entregó (2026-10-16) y la app lo consume:** `DriverRouteStop.customerPhone/addressReference/items` (con `image_url`), `DriverRoute.routeGeometry` (trazo por calles; si null, línea directa), `POST /app/deliveries/{id}/issues` ("Otro inconveniente" en Ayuda → `ReportIssueScreen`, cola `reportDeliveryIssue`), `PUT /app/devices/current/push-token` (cola `updateDevicePushToken` al rotar el FID con sesión) y topics `role_<rol>`/`node_<id>` suscritos por `PushController`. `Shipment.destination_node_id` lo debe poblar el ingest/SAP: mientras no, la tienda ve su lista VACÍA (por diseño). Push 1-a-1 todavía no está cableado en el backend (solo la capacidad).

**Why:** pedidos explícitos del usuario; la app la usan choferes/tienda en terreno.
**How to apply:** no reintroducir mensajes de "sin conexión/pendiente/sincronización" en UI de campo; cualquier pedido al backend va como doc en `docs/backend-requests/` (no hay sesión del backend en esta máquina para mensajear). Ver [[app-scope-backend-consumer]].
