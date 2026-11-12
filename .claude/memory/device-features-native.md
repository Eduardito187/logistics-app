---
name: device-features-native
description: Nov 2026 funciones del teléfono por canales nativos propios (sin pub nuevos): biometría, Live Updates/Dynamic Island, accesos directos, brillo, energía; batería optimizada
metadata:
  type: project
---

Pedido del dueño (11-nov-2026): biometría en perfil, "islas dinámicas", más funciones del teléfono, batería urgente (50% en 1–2 h). Decisión: **canales nativos propios** (local_auth 3.x exige Flutter 3.38; no subir Flutter). MainActivity = **FlutterFragmentActivity** (BiometricPrompt) y registra `BiometricChannel`, `LiveUpdatesChannel` (registra también `ScreenChannel`), `AppShortcutsChannel`, `PowerChannel` + `onNewIntent`. AppDelegate igual + `performActionFor shortcutItem`. Los 6 `.swift` de Runner están agregados a mano al `project.pbxproj` (ids `D15A…`). Gradle: `androidx.biometric:biometric:1.1.0`. Manifest: USE_BIOMETRIC, POST_PROMOTED_NOTIFICATIONS.

- **Biometría** `lib/core/auth/biometric/`: textos según sensor REAL (iOS Face ID/Touch ID/Optic ID; Android huella/reconocimiento facial/…); switch en perfil (oculto sin hardware, deshabilitado sin registrar), oferta post-login, botón en login, UNA cuenta por teléfono, logout no borra la credencial, 401 la borra.
- **Live Updates** `lib/core/live_updates/`: Android 16 ProgressStyle + chip + promoción (`"android.requestPromotedOngoing"` literal), <36 progress clásico; oculta con app en primer plano; iOS ActivityKit. **Falta crear el target "RouteLiveActivity" en Xcode en una Mac** (`docs/live-updates.md`).
- **Accesos directos** `lib/core/shortcuts/` por rol (máx 4).
- **Batería** (`docs/bateria.md`): telemetría por lotes cada 60 s (antes 1 POST cada 10 s = radio siempre activa), GPS adaptativo detenido/en marcha (`MotionDetector`), escáner se pausa a los 60 s, loops de íconos con tope, `TickerMode` en pestañas ocultas, modo ahorro `lib/core/power/` (<20% o ahorro del sistema). Supervisor ve el camión con ≤60 s de retraso.

**Pendiente:** nada probado en hardware; build iOS en Mac.

**2da ronda (11-nov):**
- **UNA sola notificación:** el FGS del GPS arranca con `serviceId: 4120` (= id de la notificación de ruta, `route_live_notification.dart`) y texto neutro "En servicio"; el controller re-publica la ruta encima apenas `foregroundServiceRunning` pasa a true. Ya no existe "Sesión en curso".
- **Isla en todas las versiones:** Android 16 promoción (con `hasPromotableCharacteristics` + `openPromotionSettings`); **isla propia** `IslandOverlay.kt` (pastilla overlay API 24+, permiso SYSTEM_ALERT_WINDOW "Mostrar sobre otras apps", solo en 2º plano con ruta); Xiaomi `miui.focus.param` best-effort; Samsung/Honor/OPPO/Vivo pre-16 = APIs de partner (no se usan). iOS: Live Activity desde 16.1 (pantalla de bloqueo), Dynamic Island solo 14 Pro+, target Xcode pendiente. Ajustes → "Isla de ruta" (`RouteIslandSettingsTile`, solo chofer).
- **Gradle:** plugins con Java 8 subidos a 17 en `android/build.gradle.kts` vía `androidComponents.finalizeDsl` (cambiar JavaCompile directo NO alcanza: AGP lo pisa → "Inconsistent JVM-target") + `kotlin.jvm.target.validation.mode=warning` como red. `tool/api_gen/pubspec.gen.yaml` (renombrado para que el IDE no le corra pub get con Dart 3.8).

**Widgets de pantalla de inicio (11-nov):** 6 kinds (`next_delivery`, `route_day`, `picking_pending`, `store_receptions`, `supervisor_summary`, `quick_scan`) por canal `bo.com.dismac/widgets` (update/clearAll/setEnabledKinds/requestPin). Android nativo (`WidgetsChannel.kt` + `widgets/*` RemoteViews, `updatePeriodMillis=0`, receivers exported=false); iOS WidgetKit en la MISMA extensión `ios/RouteLiveActivity/HomeWidgets/` (App Group `group.bo.com.dismac.logisticsApp`, deep link `distrack://open?route=` en AppDelegate + CFBundleURLTypes). Dart `lib/core/home_widgets/` (escucha débil de providers existentes, sin requests nuevos, throttle 60 s) + Ajustes `HomeWidgetsSection`. **OJO:** en Android deshabilitar un provider QUITA los widgets ya puestos → al logout solo `clearAll` (nunca setEnabledKinds); apagar en ajustes pide confirmación. Taps entran por `shortcut_route` y `AppShortcutsController` acepta `homeWidgetRoutesFor`. Docs: `docs/widgets.md`.
