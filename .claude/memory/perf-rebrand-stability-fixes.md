---
name: perf-rebrand-stability-fixes
description: "Crisis de rendimiento/estabilidad en dispositivo real tras el rebrand (oct 2026) y sus arreglos: storm de conectividad, splash, GPS, push, sesión expiró."
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-05T20:41:05.510Z
---

El 2026-10-21, probando en teléfono físico real (Honor Magic 5 Lite, ver [[device-run-wireless-adb]]), el dueño reportó que **la app se colgaba/calentaba/cerraba en todas las páginas "desde el rebrandeo"**. La causa NO era el rebrand en sí; eran bugs latentes que recién se manifestaron en hardware real (no en el emulador ni en los tests). Todos corregidos, sin romper la suite. Es una fase distinta de la de layout/RAM ([[perf-responsive-phase]]).

**NUEVOS fixes críticos (nov 2026, reportados en dispositivo real):**
- **Login "se logueó y al instante dijo que la sesión expiró" (intermitente):** `_AuthInterceptor.onError` en `core/network/dio_client.dart` disparaba `handleUnauthorized()` ante CUALQUIER 401 de endpoint no excluido. Un request SIN token (o con token viejo) que quedaba EN VUELO desde el arranque/login y cuyo 401 llegaba DESPUÉS del login nuevo tumbaba la sesión recién abierta (por eso intermitente, y al reintentar ya no había request viejo → funcionaba). Fix: `_isCurrentSessionToken(options)` — solo desloguea si el 401 es del Bearer de la sesión ACTUAL (compara el Authorization enviado vs `authHeadersProvider.bearerToken`); un 401 sin token o de token distinto NO cierra. Blinda también el desalojo por otro dispositivo. 2 tests de la carrera (adapter con `onFetch` que cambia la sesión en vuelo).
- **Sesiones 1-por-plataforma (nov 2026, backend `logistics-8e`):** máx 1 `web` + 1 `app` por usuario; segundo dispositivo del mismo bucket desaloja al anterior → 401 `code:session_superseded` (RFC7807) al próximo request. App cableada SIN regen: el interceptor parsea el `code` del body y `handleUnauthorized(reason:)` muestra el aviso correcto — `session_superseded`→"Iniciaste sesión en otro dispositivo", `device_revoked`→"dispositivo dado de baja", default→"sesión expiró". Backend deriva el bucket de `device.platform` (la app no manda nada nuevo). Backend entregado en working tree de `feature/commerce-fase0` (falta commit/push → regen pendiente). Ver [[labeling-order-multishipping]] (doc `2026-11-05-sesiones-una-por-plataforma-banco.md`).
- **Notificación "Sesión en curso" → ahora FANTASMA (nov 2026, pedido del dueño):** es el foreground service del rastreo GPS del chofer (`core/location/truck_tracking_service.dart`). Android OBLIGA a la notificación persistente mientras el FGS corre; NO se puede ocultar ni hacer rastreo oculto (OS + Play + legal — NO implementar rastreo encubierto). Solución compatible que pidió el dueño ("ambos, pero sin notificación con la app abierta"): el FGS (y su notificación) se levanta SOLO en segundo plano y se baja al volver a primer plano, vía `AppLifecycleListener` en `build()` (`_onLifecycleChange`: `paused`→`_startForegroundService`, `resumed`→`_stopForegroundService`; `hidden/inactive/detached`→nada para no duplicar/parpadear). `_start` ya NO levanta el FGS (solo suscribe el GPS; permiso "mientras se usa" vía `ensurePermission`), salvo que la app ya esté en segundo plano (`_isBackground`). Resultado: en primer plano cero notificación; en segundo plano sigue rastreando con la notificación neutra. Guards try/catch por el binding ausente en tests unitarios; `stopOrphanedService()` + cleanup en `main` (si no es driver) por FGS heredado. Tests con `TestWidgetsFlutterBinding` + helpers `_toBackground/_toForeground` (transiciones válidas resumed→inactive→hidden→paused).
- **Filtros booleanos en query daban 422 ("The X field must be true or false"):** retrofit serializa `bool` de query como "true"/"false" y Laravel `boolean` los rechaza (ej. `only_active` de choferes → rompía el Checklist pre-salida; `only_passed`). Fix app-wide: `DateQueryInterceptor._normalizeQuery` convierte bools del QUERY a "1"/"0" (en el body se dejan JSON true/false).
- **Resumen del vehículo:** cost-summary daba 500 porque la app mandaba la fecha con hora (ISO) y el backend esperaba `Y-m-d` → ahora `vehicleCostSummaryProvider`/`vehicleUtilizationProvider` usan fecha de calendario (medianoche) para que el interceptor la recorte. `UtilizationCard` reescrita: métricas en español formateadas (Salidas/Km/Horas/Odómetro), sin uuid ni `from/to` crudos.
- **Orientación bloqueada en vertical (teléfonos):** `main` hace `SystemChrome.setPreferredOrientations` portrait-only si `shortestSide<600dp` (tablets permiten horizontal). El dueño no quiere que rote.

**Causa principal (la que calentaba el equipo):**
- `core/offline/connectivity_notifier.dart`: drenaba AMBAS colas offline en CADA evento de conectividad (y hay muchos). Ahora drena solo en el flanco real offline→online (campo `_online`: `if (online && !wasOnline)`). Esto solo ya bajó el CPU en reposo a ~0%.

**Otros arreglos de esta tanda:**
- `core/push/push_service.dart`: `initialize()` cancelaba/limpiaba `_subs` antes de re-suscribir → dejaba de **duplicar/filtrar listeners de FCM** en cada rebuild.
- `driver/.../active_delivery_screen.dart` + `widgets/active_delivery/delivery_map.dart`: el watch del fix GPS se aisló a un `_LiveStatusCard` chico y se memoizó `_upcoming`/`_streets` en `didUpdateWidget` → el mapa dejó de reconstruirse con cada fix.
- `picking/.../order_labels_controller.dart`: `FutureProvider.family` → `FutureProvider.autoDispose.family` (no acumula estado por pedido).
- **Splash animado CABLEADO:** `BrandSplash` (Lottie) ahora se muestra al arranque vía `BootSplashGate` one-shot creado en `runApp` (en `main.dart`, NO en el `builder` de MaterialApp, para que el Lottie se cree una vez y no recargue en cada navegación). `brand_splash.dart` tiene guarda `_started` (Lottie puede re-invocar `onLoaded`), `_finish` idempotente, `errorBuilder` y failsafe de 3 s. Esto corrige lo que `distrack-rebrand` daba como "splash no cableado".

**Bug "mi sesión expiró" al loguear (importante):**
- Síntoma: al iniciar sesión, "tu sesión expiró" y vuelta al login. El backend estaba OK (curl: login, `/app/auth/me` y token → 200).
- Causa: el 401-logout global vive en `_AuthInterceptor.onError` de `core/network/dio_client.dart`. Tras el login, `AuthRepositoryImpl.login` llama `_remote.me()` (único consumidor de `/me`, "degradación segura"); un 401 ahí disparaba `handleUnauthorized()` ANTES del `try/catch` del repo.
- Arreglo: `_isAuthEndpoint` ahora excluye también `/auth/me` (además de `/login` y `/token`), así su 401 no fuerza logout. Si "sesión expiró" reaparece **al abrir la app** (no al loguear), sería un token viejo restaurado → validar/limpiar al restaurar (pendiente, solo si el dueño confirma el síntoma).

**Robustez (para que "lo más mínimo" no cierre la app sin mensaje):**
- `login_controller.dart`: `on ApiException` → `on Object` (cualquier error deja mensaje, el botón no gira para siempre).
- `settings/.../printer_section.dart`: `_save` en try/catch con `showInfoSnack` ("No se pudo guardar la impresora…").
- `driver/.../report_issue_screen.dart`: `_submit` en try/finally que resetea `_busy`.
- `core/auth/token_store.dart`: `FlutterSecureStorage(aOptions: AndroidOptions(resetOnError: true))` → el "Could not decrypt key" (clave corrupta tras reinstalar/limpiar) se recupera solo en vez de tumbar.

Ver falencias previas [[test-pass-detected-flaws]] y el rebrand [[distrack-rebrand]].
