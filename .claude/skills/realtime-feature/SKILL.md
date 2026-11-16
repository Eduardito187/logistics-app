---
name: realtime-feature
description: Add or change real-time (WebSocket / sockets, Pusher protocol) behavior in the Dismac logistics internal Flutter app — make a screen update by itself instead of polling or pull-to-refresh, consume a new backend event or topic, show a phone notification for something that arrives by socket, or debug why a screen does not update live. Use it whenever the user says "sockets", "websocket", "tiempo real", "en vivo", "que se actualice solo", "sin refrescar", "quita el polling", "que le llegue al instante", or when a new screen would otherwise need a `Timer.periodic`.
---

# Tiempo real en la app — logistics-app

**Decisión del dueño (nov 2026):** lo que tiene que estar al día va por SOCKETS, no por refresco por
tiempo. Una pantalla nueva no usa `Timer.periodic` para pedir datos: se anota a un tema de tiempo real.
El refresco por tiempo solo existe como RESPALDO cuando el tema no está en vivo.

## Cómo está armado (`lib/core/realtime/`)

| Pieza | Qué hace |
| --- | --- |
| `pusher_socket.dart` | `PusherConnection`: una conexión, varios canales (protocolo Pusher sobre `dart:io`). Sin dependencias nuevas. |
| `realtime_hub.dart` | `RealtimeHub`: LA conexión de la app. Vive con sesión y app en primer plano (en segundo plano se corta; lo urgente llega por push). Se crea en `HomeShell`. Reconecta sola (2 s → 60 s). |
| `realtime_bus.dart` | `RealtimeBus` (las pantallas se anotan a un tema; no abre red, sirve en tests), `RealtimeTopic`, `realtimeTopicLiveProvider(tema)` = ¿ese tema llega por socket ahora? |
| `realtime_refresh.dart` | `ref.refreshOnRealtime(tema, {eventos}, when:)` y `realtimeMatches(data, clave, id)`. |
| `realtime_listener.dart` | Widget `RealtimeListener(topic, onEvent, child)` con debounce de 400 ms. |

**La conexión:** `GET /app/broadcasting/config` → `{enabled, key, path, channels}`. El socket va por el
MISMO host y puerto que la API (`wss` si la API es https). La clave y los canales salen de ahí: **la app
nunca arma nombres de canal** (única excepción de compatibilidad: `private-user.{id}`). `channels` es un
mapa tema → canales del usuario; el backend decide el alcance (rol, ciudad, tienda, camión). Tema ausente =
ese usuario no tiene tiempo real ahí. Firma: `POST /app/broadcasting/auth`.

## Agregar tiempo real a una pantalla

Los eventos son **señales livianas**: avisan que algo cambió y la app vuelve a pedir el endpoint de
siempre. El payload solo necesita los ids para filtrar. Elegir la forma más simple que alcance:

1. **Un provider de lectura** (lo normal): dentro del provider,
   ```dart
   ref.refreshOnRealtime(
     RealtimeTopic.store,
     const {'store.updated'},
     when: (data) => realtimeMatches(data, 'node_id', nodeId),
   );
   ```
   Escucha solo mientras el provider está vivo; junta ráfagas (400 ms) y se invalida a sí mismo.
2. **Lista paginada** (`PagedSearchList`): `GlobalKey<PagedSearchListState<T>>` + `RealtimeListener` que
   llama `key.currentState?.refreshSilently()` — vuelve a pedir las páginas ya cargadas sin spinner y sin
   mover el scroll.
3. **Estado propio de la pantalla** (búsqueda en un `State`, cerrar un detalle borrado): `RealtimeListener`
   con `onEvent`.
4. **Aplicar el dato sin volver a pedir** (flota): el evento trae el objeto completo y un `AsyncNotifier`
   lo aplica (`FleetLive.apply`). Solo cuando hay muchos eventos por minuto.

Un tema nuevo: constante en `RealtimeTopic` + pedirle al backend que lo incluya en `channels` (ver skill
**backend-coordination**). Un campo ausente o `null` en el payload se trata como "cambio general".

**Respaldo sin socket:** si la pantalla YA refrescaba por tiempo, el timer corre solo cuando
`realtimeTopicLiveProvider(tema)` es `false`. Si nunca refrescó por tiempo, no se agrega nada.

## Temas y eventos vigentes

| Tema | Eventos (payload) | Lo consume |
| --- | --- | --- |
| `user` | `inbox.updated {unread}`, `notifications.updated {scope}`, `route.updated {route_id, vehicle_id}` | Bandejas de avisos y notificaciones; hoja de ruta del chofer |
| `fleet` | `fleet.position` (objeto `VehicleLive`), `fleet.removed {vehicle_id}` | Flota en vivo |
| `planning` | `planning.run.updated {plan_date, status, run}`, `plans.updated {plan_date, plan_id, deleted}` | Lista y detalle de planes |
| `picking` | `picking.updated {shipment_id, order_reference, plan_id, vehicle_id}` | Pedidos por preparar y armado del pedido |
| `store` | `store.updated {node_id, shipment_id}` | Bandeja y recepción de la tienda |
| `tracking` | `tracking.updated {shipment_id, order_reference, status, event}` | Consultar pedido, Envíos del admin |
| `operations` | `alerts.updated {alert_id}`, `dashboard.updated {plan_date}` | Alertas y tablero |
| `loading` | `loading.updated {vehicle_id, shipment_id}` | Hoja de carga del chofer |

El estado real de cada uno (emitido / desplegado en staging) está en la memoria `realtime-sockets-contract`
y en `docs/backend-requests/2026-11-15-tiempo-real-en-lugar-de-refresco-por-tiempo.md`. **Antes de decir
que algo "ya funciona en vivo", confirmar que el backend lo emite y que está desplegado.**

## Lo que NO va por sockets

- **Escaneos, entregas, fotos, firmas:** cola offline (`offlineQueueProvider`). Un socket se cae sin señal.
- **Envío del GPS del camión:** por lotes HTTP (`/tracking/.../position`); gasta menos batería.
- **Pantallas que se abren poco** (historial, documentos, reportes): cargar al entrar alcanza.

## Aviso en el teléfono para lo que llega por socket

`core/push/local_alerts.dart` (`LocalAlerts`: `enable()` pide el permiso, `show(title:, body:)`) muestra una
notificación del sistema sin pasar por Firebase. `InboxAlerts` (features/notifications) la usa cuando sube
la cantidad de avisos sin leer, y NO la muestra si el push FCM ya está registrado (saldría dos veces).

## Tests

- Pantallas: no hace falta red. `ProviderScope.containerOf(...)` → `realtimeBusProvider.dispatch(tema,
  (channel: 'c', name: 'x.updated', data: {...}))` y `realtimeLiveProvider.notifier.set({tema})`.
- **`pumpAndSettle` no avanza timers:** tras un evento con debounce, primero
  `await tester.pump(const Duration(milliseconds: 500))`.
- Conexión: `realtimeEndpointProvider` y `realtimeConnectorProvider` son los seams (socket falso en
  `test/core/realtime/realtime_hub_test.dart`).

## Trampas ya vistas

| Síntoma | Causa | Arreglo |
| --- | --- | --- |
| `Cannot use Ref or modify other providers inside life-cycles` al cerrar | `ref.read` dentro de `ref.onDispose` | Guardar la referencia en un campo durante `build` |
| "Tried to modify a provider while the widget tree was building" | Un `dispose`/`initState` de widget termina cambiando otro provider | Hacerlo en una microtarea |
| La pantalla "en vivo" no se entera de nada | El tema no viene en `channels` para ese rol, o el backend no emite todavía | Mirar la respuesta de `/app/broadcasting/config`; pedirlo al backend |
| En dev no conecta desde el teléfono | Falta el `adb reverse` del 8110 (el socket va por el mismo puerto que la API) | `adb reverse tcp:8110 tcp:8110` |
| Dos notificaciones por un mismo aviso | Socket + push FCM a la vez | `InboxAlerts` ya lo evita; no mostrar locales si el push está registrado |
