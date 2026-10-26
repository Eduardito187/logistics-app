---
name: perf-rebrand-stability-fixes
description: "Crisis de rendimiento/estabilidad en dispositivo real tras el rebrand (oct 2026) y sus arreglos: storm de conectividad, splash, GPS, push, sesión expiró."
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-22T02:31:39.841Z
---

El 2026-10-21, probando en teléfono físico real (Honor Magic 5 Lite, ver [[device-run-wireless-adb]]), el dueño reportó que **la app se colgaba/calentaba/cerraba en todas las páginas "desde el rebrandeo"**. La causa NO era el rebrand en sí; eran bugs latentes que recién se manifestaron en hardware real (no en el emulador ni en los tests). Todos corregidos, sin romper la suite. Es una fase distinta de la de layout/RAM ([[perf-responsive-phase]]).

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
