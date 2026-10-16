# Firebase: paso a paso para activar push y Crashlytics

La app ya tiene todo el código de **Firebase Cloud Messaging** (push) y **Crashlytics** (errores en
terreno). **Sólo faltan las credenciales.** Sin ellas la app funciona igual: el push queda
"No disponible" y los errores no se reportan.

No se usan `google-services.json` ni `GoogleService-Info.plist` ni el plugin de Gradle de Google:
la app arma las `FirebaseOptions` desde `config/<entorno>.json`
(`lib/core/push/firebase_options.dart`), que se inyecta con `--dart-define-from-file`.

Datos fijos de la app:

| | Valor |
|---|---|
| Paquete Android (`applicationId`) | `bo.com.dismac.logistics_app` |
| Bundle ID iOS | `bo.com.dismac.logisticsApp` |

## 1. Crear el proyecto

1. Entrar a <https://console.firebase.google.com/> con la cuenta corporativa → **Agregar proyecto**.
2. Nombre sugerido: `dismac-logistics` (uno por entorno si se quiere aislar:
   `dismac-logistics-dev` / `-staging` / `-prod`; o uno solo para todos). Anotar el **ID del
   proyecto** (puede diferir del nombre).
3. Google Analytics: no hace falta (se puede desactivar). Crashlytics funciona sin Analytics.
4. **El backend debe usar el mismo proyecto** que la app del entorno (ver paso 6).

## 2. App Android

1. *Configuración del proyecto* (engranaje) → *General* → *Tus apps* → ícono **Android**.
2. Nombre del paquete: `bo.com.dismac.logistics_app` (exacto). Apodo: `Logística interna`.
3. SHA-1: opcional (no se usa Google Sign-In). Registrar.
4. Saltar la descarga de `google-services.json` y los pasos del SDK (no se usan).
5. Copiar de esa misma pantalla (o del `google-services.json` si se bajó) los valores del paso 4.

## 3. App iOS + clave APNs

1. *Tus apps* → **Agregar app** → **iOS**. Bundle ID: `bo.com.dismac.logisticsApp` (exacto).
   Saltar la descarga de `GoogleService-Info.plist` (o bajarlo sólo para copiar valores; no se
   versiona).
2. Push en iOS necesita una **clave APNs** de Apple:
   1. <https://developer.apple.com/account> → *Certificates, IDs & Profiles* → *Keys* → **+**.
   2. Marcar **Apple Push Notifications service (APNs)** → crear → **descargar el `.p8`** (se baja una
      sola vez) y anotar el **Key ID** y el **Team ID** (arriba a la derecha).
   3. En Firebase: *Configuración del proyecto* → *Cloud Messaging* → *Configuración de apps de
      Apple* → **Subir clave de autenticación de APNs** con el `.p8`, Key ID y Team ID.
   4. Guardar el `.p8` en el gestor de secretos del equipo (no en el repo).
3. En Xcode, el target Runner necesita las capabilities **Push Notifications** y **Background Modes →
   Remote notifications** (detalle de la parte iOS en `docs/ios.md`).

## 4. Dónde va cada valor en `config/*.json`

Completar `config/dev.json`, `config/staging.json` y `config/production.json` (cada uno con el
proyecto de su entorno):

| Clave | Dónde está en Firebase | Ejemplo de forma |
|---|---|---|
| `FIREBASE_API_KEY` | App Android → *Clave de API web* / `google-services.json` → `client[].api_key[].current_key` | `AIza…` (39 caracteres) |
| `FIREBASE_APP_ID` | App Android → *ID de la app* / `mobilesdk_app_id` | `1:123456789012:android:abc123…` |
| `FIREBASE_MESSAGING_SENDER_ID` | *Configuración → Cloud Messaging* → *ID del remitente* (= número del proyecto) | `123456789012` |
| `FIREBASE_PROJECT_ID` | *Configuración → General* → *ID del proyecto* | `dismac-logistics` |
| `FIREBASE_IOS_APP_ID` | App iOS → *ID de la app* / `GOOGLE_APP_ID` del plist | `1:123456789012:ios:def456…` |
| `FIREBASE_IOS_BUNDLE_ID` | Fijo | `bo.com.dismac.logisticsApp` |
| `FIREBASE_IOS_API_KEY` *(opcional)* | `API_KEY` del plist de iOS (Firebase suele dar otra clave por plataforma). Vacía = se usa `FIREBASE_API_KEY` | `AIza…` |

Notas:

- Estos valores **no son secretos de servidor** (viajan dentro del APK), pero igual conviene
  restringir la API key en Google Cloud Console (*APIs y servicios → Credenciales*) a la app Android
  (paquete + SHA-1) y a la app iOS (bundle ID).
- Si se usa un único proyecto para todos los entornos, los tres `config/*.json` llevan los mismos
  valores de Firebase.
- Con las cuatro claves Android (`API_KEY`, `APP_ID`, `MESSAGING_SENDER_ID`, `PROJECT_ID`) ya
  funciona en Android; las `IOS_*` sólo hacen falta para el build de iOS.

### Verificar sin mostrar valores

```powershell
.\scripts\check-config.ps1                 # todos los entornos
.\scripts\check-config.ps1 -Env production # uno
.\scripts\check-config.ps1 -AllowEmptyDev  # tolera dev sin Firebase
```

Lista cada clave como `OK`, `VACIA`, `FALTA` o `FORMATO` (tiene valor pero no la forma esperada,
p. ej. un App ID de iOS en la clave de Android). **Nunca imprime los valores.** Sale con código 1 si
falta alguna requerida.

## 5. Crashlytics

- Se activa **con el mismo proyecto y las mismas claves**: no hay configuración extra en la app.
  `initCrashReporting()` inicializa Firebase si hay credenciales y habilita la colección **sólo en
  release** (`kReleaseMode`).
- En la consola: *Crashlytics* → **Habilitar**. El primer reporte aparece tras el primer crash o
  error no capturado de un build release (puede tardar unos minutos).
- Los errores Dart llegan legibles. Si el release se compila con `--obfuscate
  --split-debug-info=<dir>`, subir los símbolos para desofuscar:
  `firebase crashlytics:symbols:upload --app=<FIREBASE_APP_ID> <dir>` (Firebase CLI). Crashes
  nativos (NDK) sin símbolos no se simbolizan porque no se usa el plugin de Gradle de Crashlytics.

## 6. Service account para el backend

El backend envía los push (FCM HTTP v1) y necesita credenciales de servidor del **mismo proyecto**:

1. *Configuración del proyecto* → *Cuentas de servicio* → **Generar nueva clave privada** → se baja
   un JSON (`dismac-logistics-firebase-adminsdk-….json`).
2. Entregarlo al equipo del backend por un canal seguro (gestor de secretos), **nunca** en el repo de
   la app ni en `config/*.json`.
3. En el `.env` del backend: `FCM_PROJECT_ID=<FIREBASE_PROJECT_ID>` y la ruta/contenido del JSON de
   la cuenta de servicio (según lo que espere `FcmChannelSender`).
4. Permiso mínimo de la cuenta: *Firebase Cloud Messaging API Admin* (rol
   `roles/firebasecloudmessaging.admin`). Verificar que la **Firebase Cloud Messaging API (V1)**
   esté habilitada en *Configuración → Cloud Messaging*.

## 7. Probar

1. Correr la app con el botón de play del entorno (usa `--dart-define-from-file=config/<env>.json`).
2. Iniciar sesión → campana de notificaciones → **Activar notificaciones** → aceptar el permiso.
3. Desde la consola: *Messaging* → *Nueva campaña* → *Notificaciones* → *Enviar mensaje de prueba*
   requiere un token; más simple: enviar a un **topic** al que la app ya se suscribe al iniciar sesión,
   `role_<rol>` (p. ej. `role_chofer`) o `node_<id>` para una tienda.
4. Crashlytics: en un build release, forzar un error de prueba y revisar la consola.

Cómo funciona el push dentro de la app (registro FID, topics, payload): `docs/push-fcm.md`.
