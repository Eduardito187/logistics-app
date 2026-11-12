# Funciones del teléfono: ruta en vivo, accesos directos y brillo del QR

Pedido del dueño (nov 2026): "usar más funciones del dispositivo; en segundo plano mostrar más
interacciones con las islas dinámicas". Todo con canales nativos propios, **sin paquetes de pub ni
dependencias de Gradle**.

| Función | Dart | Android | iOS |
| --- | --- | --- | --- |
| Ruta en vivo (chofer) | `lib/core/live_updates/` | `LiveUpdatesChannel.kt` + `IslandOverlay.kt` | `LiveUpdatesChannel.swift` + `RouteActivityAttributes.swift` + extensión `ios/RouteLiveActivity/` |
| Accesos directos del ícono | `lib/core/shortcuts/` | `AppShortcutsChannel.kt` | `AppShortcutsChannel.swift` |
| Brillo máximo al mostrar un QR | `lib/core/device/` | `ScreenChannel.kt` | `ScreenChannel.swift` |
| Vibración al llegar a la parada | `route_live_updates_provider.dart` | — (HapticFeedback) | — |

## 1. Ruta en vivo del chofer

Qué ve el chofer (solo rol chofer, solo con una parada activa de HOY):

- **Android 16+** (Pixel, Samsung One UI 8…): notificación *Live Update* promovida → **chip en la barra
  de estado** con la hora de llegada ("14:20"), "Llegó" o "3/8"; en la cortina, `ProgressStyle` con un
  tramo por parada, un punto por parada atendida y el camión como marcador del avance.
- **Android 7–15**: notificación fija silenciosa con barra de progreso clásica.
- **iOS 16.1+**: Live Activity en la pantalla bloqueada y en la **Dynamic Island** (compacta:
  camión + "3/8" y la ETA; expandida: cliente, ETA, barra de avance y "Llegaste / Entregando / A 2,3 km").
- Título "Parada 3 de 8 · Llega 14:20", texto = cliente. Acciones (Android): **Navegar** (geo: → Google
  Maps/Waze) y **Abrir** (la app en "Entrega en curso").
- Estados: *En camino* → *Llegaste* (geocerca 60 m, con histéresis hasta 120 m para que no parpadee) →
  *Entregando* (90 s quieto en la geocerca) → *Ruta completada* (se quita; en iOS queda 5 min en la
  pantalla bloqueada).
- Al entrar en la geocerca de una parada el teléfono **vibra una vez** (con la app en pantalla).

Reglas de batería (`RouteLiveUpdatesController`):

- No pide GPS propio: usa el fix del rastreo que ya corre (`truckTrackingProvider.lastFix`).
- Publica al instante solo si cambia parada / estado / avance / cliente / ETA. Si solo cambia la
  distancia redondeada ("2,3 km" → "2,1 km"), **máximo un update cada 30 s**. Igual → nada. Sin timers.
- **Android: con la app en pantalla la notificación se quita** (decisión del dueño: nada de
  notificaciones con la app abierta, igual que la del rastreo) y vuelve al pasar a segundo plano.
- iOS: la Live Activity solo se puede PEDIR con la app en primer plano (ActivityKit); se pide apenas hay
  ruta y se actualiza en segundo plano mientras el rastreo mantiene viva la app.
- Al cerrar sesión, cambiar a otro rol o terminar la ruta → `end`. Al arrancar sin ruta se limpia una
  notificación huérfana de una ejecución anterior.

### Una sola notificación (rastreo + ruta, nov 2026)

Antes había dos en segundo plano: la de la ruta y la del foreground service del GPS ("DisTrack · Sesión
en curso"). Android EXIGE una notificación mientras corre el servicio, así que ahora **la de la ruta ES la
del servicio**: mismo id **4120** (`routeLiveNotificationId` en
`lib/core/live_updates/route_live_notification.dart` = `NOTIFICATION_ID` de `LiveUpdatesChannel.kt` =
`serviceId` de `FlutterForegroundTask.startService`). Al publicar con el id del servicio, Android le
re-aplica `FLAG_FOREGROUND_SERVICE` y usa el canal de la última publicación (`route_live`), así que no
queda otra notificación "silenciada" en el canal del plugin.

Quién postea la 4120 y cuándo:

```
App → 2.º plano
  ├─ RouteLiveUpdatesController.setForeground(false) → start/update  (notify 4120, canal route_live)
  └─ TruckTrackingService → startService(serviceId: 4120, "DisTrack" / "En servicio")
        plugin: startForeground(4120, texto neutro, canal dismac_truck_tracking)   ← pisa a la ruta
        Dart: state.foregroundServiceRunning = true
           → routeLiveServiceRunningProvider → controller.setServiceRunning(true)
           → update forzado con la última foto  (notify 4120: gana el contenido de ruta, sigue siendo FGS)
Cambios de ruta en 2.º plano → update (mismo throttling: 1 cada 30 s si solo cambia la distancia)
Ruta termina / logout con el servicio arriba → "end": cancel NO tiene efecto sobre un FGS →
  el nativo la deja neutra ("Ruta completada" o "DisTrack · En servicio") sin promoción
App → 1.er plano → TruckTrackingService.stopService → stopForeground(REMOVE) se la lleva
  → foregroundServiceRunning = false → controller: oculta (regla de primer plano)
Servicio baja con la app en 2.º plano → la ruta se vuelve a publicar como notificación normal
```

Reglas: con el servicio corriendo el controller **no** cancela la 4120 en primer plano (no tendría efecto);
se va sola cuando el rastreo baja el servicio. El texto del plugin es neutro (no el estado de ruta) a
propósito: si el sistema reinicia el servicio sin la app (proceso muerto) ese texto quedaría viejo; con la
app viva, el siguiente cambio de ruta lo vuelve a pisar. Costo: +1 `notify` por paso a segundo plano.

### Isla: del sistema (Android 16) o de DisTrack (cualquier Android)

`routeIslandModeProvider` (`lib/core/live_updates/route_island.dart`) elige **una** (nunca las dos):

| Disponible | Isla |
| --- | --- |
| Solo Live Updates del sistema (Android 16, promoción permitida) | Sistema |
| Solo permiso "Mostrar sobre otras apps" | DisTrack |
| Las dos | Preferencia del chofer (Ajustes → Isla de ruta); por defecto **Sistema** |
| Ninguna | Solo la notificación |

- **Isla del sistema**: notificación con `ProgressStyle`, chip (`setShortCriticalText`) y
  `"android.requestPromotedOngoing"`.
- **Isla de DisTrack** (`IslandOverlay.kt`, Views puras, sin dependencias): pastilla flotante arriba al
  centro bajo la barra de estado / recorte (`WindowInsets` API 30+, alto de la barra de estado antes).
  Compacta: camión + "3/7 · 08:15"; tocar → tarjeta con parada, cliente, distancia y **Navegar / Abrir**; tocar
  afuera o deslizar arriba → compacta; arrastrable en X. Solo con la app en segundo plano y ruta activa;
  se quita (removeView) al volver a la app, al terminar la ruta o al cerrar sesión. Mismas fotos y
  throttling que la notificación; sin timers ni animaciones en loop. Con esta isla la notificación va
  **sin** pedido de promoción (`setPromotionEnabled(false)`) para no duplicar con el chip del sistema.
  Sin permiso no hace nada. El permiso `SYSTEM_ALERT_WINDOW` lo declara el manifest.
- Al volver a la app se re-consulta la disponibilidad (el chofer pudo dar el permiso en Ajustes).

#### Requisitos de promoción (Android 16) — verificados en `LiveUpdatesChannel.kt`

| Requisito | Cómo se cumple |
| --- | --- |
| `ongoing` | `setOngoing(true)` |
| Título | `setContentTitle("Parada N de M · Llega HH:MM")` |
| Estilo estándar / BigText / Call / Progress | `Notification.ProgressStyle` (o sin estilo si no hay paradas) |
| Sin `customContentView` | No se usan vistas propias |
| NO colorizada | `setColorized(false)` (solo `setColor` de acento) |
| Canal no `IMPORTANCE_MIN` | `route_live` en `IMPORTANCE_DEFAULT` (si el usuario lo baja a MIN → razón `channelImportanceMin`) |
| Pedido de promoción | extra `"android.requestPromotedOngoing" = true` (literal; la constante no está en el jar público) |
| Usuario no apagó "Live updates" | `NotificationManager.canPostPromotedNotifications()` |
| Chip | `setShortCriticalText` ("08:15", "Llegó", "3/8"); `setShowWhen(false)` + `setUsesChronometer(false)` + `setWhen` fijo |
| Ícono monocromo | `ic_stat_route` (vector blanco sobre transparente) |

Diagnóstico: método `promotionStatus` → `{sdk, canPostPromoted, promotable
(Notification.hasPromotableCharacteristics()), promotedNow (FLAG_PROMOTED_ONGOING), channelImportance,
reasons}`. Razones: `sdk`, `notificationsDisabled`, `channelBlocked`, `channelImportanceMin`,
`promotionDenied`, `colorized`, `notOngoing`, `noTitle`, `notPromotable`. `openPromotionSettings` abre
`Settings.ACTION_APP_NOTIFICATION_PROMOTION_SETTINGS` (fallback: notificaciones de la app → ficha de la
app).

#### Versiones mínimas y matriz por fabricante

| Plataforma / fabricante | Mínimo | Qué se ve | Seguro / depende del OEM |
| --- | --- | --- | --- |
| iOS — Live Activity (pantalla de bloqueo) | iOS 16.1 | Tarjeta en la pantalla bloqueada | Seguro (falta el target en Xcode) |
| iOS — Dynamic Island | iPhone 14 Pro o posterior | Isla compacta/expandida | Seguro (falta el target en Xcode) |
| Android stock / Pixel | Android 16 (API 36) | Chip en la barra de estado + Live Update | Seguro (API pública) |
| Samsung One UI 8 | Android 16 | Now Bar / chip | Depende de One UI (mapea el Live Update estándar) |
| OnePlus / OPPO (OxygenOS / ColorOS 16) | Android 16 | Live Alerts / cápsula | Depende del OEM (estándar de Android 16) |
| Honor MagicOS 10 | Android 16 | Magic Capsule | Depende del OEM (estándar de Android 16) |
| Xiaomi / Redmi / POCO HyperOS | HyperOS 2+ (focus) / HyperOS 3 (Android 16) | Super Island | Best-effort: extra `miui.focus.param` (JSON `param_v2`: ticker, baseInfo título/texto, progressInfo); HyperOS puede exigir que Xiaomi habilite la app; en Android 16 también aplica el estándar |
| Samsung/OPPO/Vivo/Honor pre-16 | — | — | APIs privadas con convenio de partner: **no se usan** |
| Cualquier Android | Android 7 (API 24) | **Isla de DisTrack** (pastilla propia) | Seguro, requiere permiso "Mostrar sobre otras apps" |
| Android 8–15 sin permiso | Android 7 | Notificación fija con barra de progreso | Seguro |


## 2. Accesos directos del ícono

Mantener presionado el ícono de DisTrack muestra (según el rol de la sesión, mismo filtro rol+permiso
que el inicio, máx. 4; ids en `kRoleShortcutTaskIds`):

| Rol | Accesos |
| --- | --- |
| Chofer | Entrega en curso · Mi ruta de hoy · Carga del camión · Reportar incidente |
| Preparador | Pedidos por preparar · Ingresar pedido |
| Tienda | Recepción de mercadería · Recojo en tienda |
| Transportista | Escanear al recoger · Escanear al entregar |
| Supervisor | Flota en vivo · Alertas · Tablero del día |

Sin sesión no hay accesos (se borran al cerrar sesión). Un acceso tocado sin sesión queda pendiente y se
abre después del login si el rol lo tiene. Una ruta que no es acceso del rol se ignora (un intent ajeno
no abre pantallas). El "Abrir" de la notificación de ruta en vivo usa el mismo camino (extra
`shortcut_route`).

## 3. Brillo máximo al mostrar un QR

`MaxBrightnessWhileVisible` envuelve la etiqueta de la vista previa (`label_preview_sheet.dart`): mientras
está abierta la pantalla va al máximo (sin impresora, otro escanea el QR desde el teléfono, bajo el sol)
y vuelve sola al cerrar. Android cambia solo el brillo de la ventana de la app (sin permisos); iOS guarda
y restaura el brillo del usuario (también al salir/volver de la app).

Ya existían y no se duplicaron: vibración+sonido de escaneo (`scan_feedback.dart`) y linterna en los
escáneres (`toggleTorch` en `scanner_screen.dart` y `continuous_scanner.dart`).

## Cableado que hace el coordinador

0. **Ajustes → "Isla de ruta"** (`lib/features/driver/presentation/widgets/route_island_settings_tile.dart`):
   en `lib/features/settings/presentation/settings_screen.dart`, dentro de `FieldUseSection`
   (o justo después de ella, antes de `SessionSection`), agregar `const RouteIslandSettingsTile()`. Se
   oculta sola para roles que no son chofer y en plataformas que no son Android/iOS. Manifest:
   `<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>`.

1. `lib/app.dart`, dentro de `LogisticsApp.build` junto a `crashSessionBinderProvider`:

   ```dart
   import 'core/live_updates/route_live_updates_provider.dart';
   import 'core/shortcuts/app_shortcuts_provider.dart';
   // …
   ref.listen(routeLiveUpdatesProvider, (_, _) {});
   ref.listen(appShortcutsProvider, (_, _) {});
   ```

2. `MainActivity.kt` (Android, accesos/“Abrir” con la app ya abierta):

   ```kotlin
   import android.content.Intent
   // …dentro de class MainActivity:
   override fun onNewIntent(intent: Intent) {
       super.onNewIntent(intent)
       setIntent(intent)
       AppShortcutsChannel.onNewIntent(intent)
   }
   ```

   `LiveUpdatesChannel.register` y `AppShortcutsChannel.register` ya se llaman. `ScreenChannel` lo
   registra `LiveUpdatesChannel.register` (no hace falta otra línea).

3. `AppDelegate.swift` (iOS), dentro de la clase `AppDelegate`:

   ```swift
   override func application(
     _ application: UIApplication,
     performActionFor shortcutItem: UIApplicationShortcutItem,
     completionHandler: @escaping (Bool) -> Void
   ) {
     completionHandler(AppShortcutsChannel.handle(shortcutItem))
   }
   ```

   (iOS la llama también en el arranque en frío porque `didFinishLaunching` devuelve `true`; el canal
   guarda la ruta hasta que Dart la pida.) `ScreenChannel` lo registra `LiveUpdatesChannel.register`.

## Xcode (en una Mac) — agregar archivos y el target "RouteLiveActivity"

No se puede compilar iOS en Windows. En una Mac, con `ios/Runner.xcworkspace` abierto:

1. **Archivos del Runner.** Arrastrar a la carpeta `Runner` del navegador (✔ *Copy items if needed*
   desmarcado, ✔ target **Runner**): `LiveUpdatesChannel.swift`, `RouteActivityAttributes.swift`,
   `AppShortcutsChannel.swift`, `ScreenChannel.swift` (más `BiometricChannel.swift`/`PowerChannel.swift`
   si todavía no están).
2. **Nuevo target.** *File → New → Target… → iOS → Widget Extension*.
   - Product Name: `RouteLiveActivity`; ✔ **Include Live Activity**; ✘ *Include Configuration App
     Intent*; Embed in Application: **Runner**. Si pregunta "Activate scheme?", *Cancel* (se sigue
     usando el esquema Runner).
   - Xcode crea una carpeta `RouteLiveActivity/` con plantillas: **borrar** las plantillas generadas
     (`RouteLiveActivity.swift`, `RouteLiveActivityLiveActivity.swift`, `RouteLiveActivityBundle.swift`,
     `AppIntent.swift`, `Assets.xcassets` si no se usa) *Move to Trash*, y en su lugar agregar al target
     **RouteLiveActivity** los archivos versionados de `ios/RouteLiveActivity/`:
     `RouteLiveActivityBundle.swift`, `RouteLiveActivityWidget.swift`, `Info.plist` (no marcarlo en
     *Target Membership*; se referencia por build setting), `RouteLiveActivity.xcconfig`.
3. **Membership compartida.** Seleccionar `Runner/RouteActivityAttributes.swift` → *File inspector →
   Target Membership*: ✔ **Runner** y ✔ **RouteLiveActivity** (los dos procesos deben ver el mismo tipo).
4. **Build settings del target RouteLiveActivity** (Debug, Release y Profile):
   - *Project → Info → Configurations*: para RouteLiveActivity elegir `RouteLiveActivity.xcconfig` en
     las tres configuraciones (trae `FLUTTER_BUILD_NAME/NUMBER` y el mínimo 16.1).
   - `INFOPLIST_FILE = RouteLiveActivity/Info.plist`; `GENERATE_INFOPLIST_FILE = NO`.
   - `PRODUCT_BUNDLE_IDENTIFIER = bo.com.dismac.logisticsApp.RouteLiveActivity` (prefijo del de la app).
   - `IPHONEOS_DEPLOYMENT_TARGET = 16.1`; `SWIFT_VERSION = 5.0`; mismo *Team* y firma que Runner
     (perfil de aprovisionamiento propio para el bundle id de la extensión en release).
   - `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`: dejarlos vacíos (vienen del xcconfig).
5. **Orden de build.** *Runner → Build Phases*: la fase *Embed Foundation Extensions* (la crea Xcode)
   debe ir **antes** de *Thin Binary* / *[CP] Embed Pods Frameworks*; si `flutter build ios` da
   "Cycle inside Runner", arrastrarla justo debajo de *Link Binary With Libraries*.
6. `ios/Runner/Info.plist` ya tiene `NSSupportsLiveActivities = YES`. El Podfile **no** necesita un
   target para la extensión (no usa pods).
7. **Widgets de inicio.** La misma extensión lleva los 6 widgets de inicio
   (`ios/RouteLiveActivity/HomeWidgets/`), con App Group y entitlements propios: seguir los pasos de
   [widgets.md](widgets.md) antes de compilar.
8. Compilar: `flutter build ios --release --dart-define-from-file=config/staging.json` (o desde Xcode
   con el esquema Runner).

## Qué probar (dispositivo real)

Android 16 (ideal Pixel 8+/Galaxy S25 con One UI 8) y un Android 10–14:

1. Login como chofer con ruta de hoy → abrir la app y pasarla a segundo plano → aparece la
   notificación "Parada N de M · Llega HH:MM" con el cliente — **UNA sola** (ya no aparece "DisTrack ·
   Sesión en curso"); en Android 16, chip con la hora en la barra de estado (si no aparece: Ajustes de
   DisTrack → *Isla de ruta* → **Activar en el sistema**).
1b. Android < 16 (o eligiendo "Isla de DisTrack"): Ajustes → *Isla de ruta* → **Permitir isla de
   DisTrack** → dar el permiso → salir de la app: aparece la pastilla arriba; tocarla expande; Navegar /
   Abrir funcionan; volver a la app la quita. Con las dos disponibles, el selector cambia una por otra
   (nunca se ven las dos).
2. Volver a la app → la notificación desaparece; salir → vuelve.
3. "Navegar" abre Maps/Waze en el cliente; "Abrir" lleva a "Entrega en curso".
4. Acercarse a menos de 60 m → "Llegaste" (vibra si la app está abierta); quedarse 90 s → "Entregando".
5. Registrar la entrega → pasa a la parada siguiente al instante; última parada → la notificación se va.
6. Cerrar sesión → se va. Login como preparador → nunca aparece.
7. Batería: con la app en segundo plano 30 min de ruta, el consumo no debe subir respecto de antes
   (como máximo ~1 update/30 s mientras se mueve; parado, ninguno).

iOS 16.1+ con Dynamic Island (iPhone 14 Pro+) y uno sin isla:

1. Chofer con ruta → con la app ABIERTA aparece la Live Activity (al bloquear se ve en la pantalla
   bloqueada; con la app en segundo plano, en la isla: camión + "3/8" y la ETA).
2. Mantener presionada la isla → vista expandida con cliente, ETA y barra roja.
3. *Ajustes → DisTrack → Live Activities* apagado → no aparece nada y la app sigue igual.
4. Terminar la ruta → "Ruta completada" queda ~5 min en la pantalla bloqueada.

Accesos directos (ambos SO): mantener presionado el ícono con cada rol → los accesos de la tabla; tocar
uno con la app cerrada y con la app abierta en segundo plano → abre esa pantalla (una sola vez); cerrar
sesión → el ícono ya no muestra accesos.

Brillo: Preparador → vista previa de una etiqueta → el brillo sube al máximo; cerrar → vuelve.
