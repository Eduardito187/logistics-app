# iOS

Decisión del dueño: la app **sí** tendrá iOS. No hay Mac en el equipo de desarrollo: el proyecto
`ios/` queda listo para compilar en una Mac o en CI (`ios-build`, `macos-latest`).

## Proyecto

| Campo | Valor |
|---|---|
| Bundle id | `bo.com.dismac.logisticsApp` (tests: `…logisticsApp.RunnerTests`) |
| Nombre visible | Dismac Logística |
| Mínimo | iOS **15.0** (lo exigen firebase_core 5 / firebase_messaging 17; Podfile, pbxproj y AppFrameworkInfo alineados) |
| Dependencias nativas | **CocoaPods** (`ios/Podfile`, `use_frameworks!`). Flutter 3.32 no usa Swift Package Manager por defecto. |
| Versión | `version:` de `pubspec.yaml` (`FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER`) |

El proyecto había sido generado con un Flutter más nuevo (UIScene, `FlutterSceneDelegate`,
`FlutterImplicitEngineDelegate`, integración SwiftPM): APIs que **no existen en Flutter 3.32**.
Se regeneró con la plantilla de 3.32 (`AppDelegate` clásico, sin `SceneDelegate`, sin SwiftPM).
Si algún día se sube Flutter, revisar la migración a UIScene.

### `Info.plist`

- Permisos (textos en español): cámara (escaneo y foto POD), ubicación *when-in-use* y *always*
  (rastreo del camión), Bluetooth (Zebra), fotos (leer y guardar), notificaciones.
- `UIBackgroundModes`: `location`, `remote-notification`, `fetch`, `processing`.
- `BGTaskSchedulerPermittedIdentifiers`:
  - `bo.com.dismac.logisticsApp.sync` → sincronización de la cola offline (workmanager).
  - `com.pravera.flutter_foreground_task.refresh` → lo pide flutter_foreground_task.
- `LSApplicationQueriesSchemes`: `tel`, `comgooglemaps`, `maps`, `geo` (url_launcher/canLaunchUrl).
- `FirebaseAppDelegateProxyEnabled = true` (firebase_messaging necesita el swizzling).
- `ITSAppUsesNonExemptEncryption = false` (solo HTTPS del sistema).

### `AppDelegate.swift`

- Registra los plugins y el callback de plugins para los isolates de fondo de **workmanager** y
  **flutter_foreground_task**.
- Registra el handler BGTaskScheduler de `bo.com.dismac.logisticsApp.sync` **durante el arranque**
  (iOS cierra la app si se registra después). El código Dart debe usar exactamente ese identificador
  como nombre único de la tarea periódica (`BackgroundSyncTasks.periodic` en
  `lib/core/background/sync_scheduler.dart`). Si se agrega otra tarea BGTaskScheduler, sumarla al
  `Info.plist` y registrarla en el AppDelegate. La tarea *one-off* de workmanager en iOS usa
  `beginBackgroundTask` y no necesita identificador permitido.
- `UNUserNotificationCenter.delegate = self` para notificaciones con la app abierta.

### `Runner.entitlements`

- `aps-environment = development` (Xcode lo pasa a `production` al exportar para TestFlight/MDM).
- Protección de datos por defecto: **`NSFileProtectionCompleteUntilFirstUserAuthentication`**.
  No se usa `NSFileProtectionComplete` a propósito: con *Complete* los archivos (cola Drift, fotos)
  quedan ilegibles con el equipo bloqueado, y el GPS en segundo plano / la sincronización (que
  escriben con la pantalla apagada) fallarían. Los tokens van al Keychain (flutter_secure_storage).
  Al activar la capability *Data Protection* en el App ID del portal de Apple debe coincidir.

### `Podfile`

- `platform :ios, '15.0'` y deployment target 15.0 en todos los pods.
- Macros de **permission_handler** (`PERMISSION_CAMERA`, `PERMISSION_LOCATION*`,
  `PERMISSION_NOTIFICATIONS`, `PERMISSION_BLUETOOTH`, `PERMISSION_PHOTOS`): sin ellas el plugin
  responde "denegado" sin preguntar. Mantener en sync con los textos del `Info.plist`.

## Firebase (push)

Igual que en Android, sin archivo de configuración nativo: las credenciales van en
`config/<entorno>.json` y `lib/core/push/firebase_options.dart` arma las opciones según la plataforma.

1. Consola de Firebase → proyecto → *Agregar app* → iOS, bundle id `bo.com.dismac.logisticsApp`.
2. Del `GoogleService-Info.plist` que descarga, copiar a `config/<entorno>.json`:
   - `GOOGLE_APP_ID` → `FIREBASE_IOS_APP_ID`
   - `API_KEY` → `FIREBASE_IOS_API_KEY` (opcional; vacía = usa `FIREBASE_API_KEY`, pero Firebase
     suele restringir la key de Android a Android, así que conviene cargarla)
   - `BUNDLE_ID` → `FIREBASE_IOS_BUNDLE_ID`
   - `GCM_SENDER_ID` y `PROJECT_ID` son los mismos que ya usa Android.
   No hace falta agregar el `.plist` al proyecto (está en `.gitignore` por si alguien lo baja).
3. **APNs**: en developer.apple.com → *Keys* → crear una key con *Apple Push Notifications service*
   (archivo `.p8`, anotar Key ID y Team ID). Subirla en Firebase → Configuración → *Cloud Messaging*
   → app iOS → *APNs Authentication Key*. Sin esto FCM no entrega nada a iOS.
4. Con `FIREBASE_IOS_APP_ID` vacío el push en iOS queda desactivado (la app funciona igual).

## Firma y distribución

Requisitos: cuenta Apple Developer de la empresa (o **Apple Developer Enterprise Program** si se
distribuye por MDM fuera de la App Store), una Mac con Xcode 16.x.

1. developer.apple.com → *Identifiers* → App ID `bo.com.dismac.logisticsApp` con capabilities
   **Push Notifications**, **Background Modes** y **Data Protection**.
2. En Xcode (`ios/Runner.xcworkspace`) → Runner → *Signing & Capabilities* → Team de Dismac,
   firma automática. Verificar que tome `Runner/Runner.entitlements`.
3. Distribución, a elegir:
   - **TestFlight / App Store (Unlisted o Custom App vía Apple Business Manager)**:
     `flutter build ipa --release --dart-define-from-file=config/production.json` y subir el
     `.ipa` con Transporter o `xcrun altool`.
   - **MDM** (Custom App por Apple Business Manager, o Enterprise in-house): exportar el `.ipa`
     con el perfil correspondiente y cargarlo en el MDM.
4. Subir el *build number* (`+N` del `pubspec.yaml`) en cada envío.

## Compilar

En una Mac:

```bash
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ios --no-codesign --dart-define-from-file=config/dev.json   # verificación
flutter run --dart-define-from-file=config/dev.json                       # simulador/dispositivo
```

> El backend local por `http://10.0.2.2` es de Android. En el simulador de iOS usar
> `http://localhost:8110/api/v1` (iOS bloquea http por ATS: para desarrollo agregar una excepción
> `NSAppTransportSecurity` solo a `localhost` en un esquema de debug, nunca en release) o un backend https.

CI: job `ios-build` (`macos-latest`, Flutter 3.32.0) corre
`flutter build ios --release --no-codesign --dart-define-from-file=config/dev.json` en cada PR/push.
No firma ni publica.
