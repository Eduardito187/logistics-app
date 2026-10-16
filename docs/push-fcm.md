# Push con Firebase Cloud Messaging (FCM)

La app recibe push con **Firebase Cloud Messaging** (`firebase_core` + `firebase_messaging`). El
envío lo hace el backend (canal `FCM`).

## Estado

Todo el código está listo. **Solo faltan las credenciales.** Sin ellas la app funciona igual: el push
queda "No disponible" en la bandeja de notificaciones y no se inicializa Firebase.

## Activarlo (una sola vez)

1. En la [consola de Firebase](https://console.firebase.google.com/) crear (o usar) el proyecto y
   agregar una **app Android** con el paquete `bo.com.dismac.logistics_app`.
2. En *Configuración del proyecto → General → Tus apps → app Android* copiar los cuatro valores y
   ponerlos en `config/dev.json`, `config/staging.json` y `config/production.json`:

   | Clave en `config/*.json`        | Dónde está en Firebase                         |
   |---------------------------------|------------------------------------------------|
   | `FIREBASE_API_KEY`              | Clave de API web / `current_key`               |
   | `FIREBASE_APP_ID`               | ID de la app (`1:…:android:…`)                 |
   | `FIREBASE_MESSAGING_SENDER_ID`  | Número del proyecto (ID del remitente)         |
   | `FIREBASE_PROJECT_ID`           | ID del proyecto                                |

   No hace falta `google-services.json` ni el plugin de Gradle de Google: la app arma las
   `FirebaseOptions` con esas claves (`lib/core/push/firebase_options.dart`).
3. El backend usa el **mismo** proyecto de Firebase (`FCM_PROJECT_ID` + credenciales del service
   account en su `.env`).
4. Correr la app con el botón de play del entorno (usa `--dart-define-from-file=config/<env>.json`) y
   en **Notificaciones → Activar notificaciones** aceptar el permiso.

## Cómo funciona en la app

- `PushController` (`lib/core/push/push_controller.dart`): al arrancar inicializa Firebase si hay
  credenciales; si el permiso ya estaba concedido, se re-registra solo.
- Registro: `FirebaseMessaging.register()` → el identificador del dispositivo (FID, API vigente de
  `firebase_messaging` 17) llega por `onRegistered`, se guarda en el almacén seguro y viaja al backend
  como `device.push_token` en el login.
- Mensajes: con la app abierta se muestran como notificación local (canal Android `operacion`); en
  segundo plano/cerrada los muestra el sistema (los solo-`data` los muestra `pushBackgroundHandler`).
- Tocar una notificación abre la bandeja. Payload: `notification_id` > `shipment_id` > `tag` > `id`
  (mismo `data` que publica el backend).
- Topics: `PushService.subscribeToTopic(topic)` está lista (p. ej. `NotificationView.fcmTopic`).

- Rotación del identificador con sesión abierta: se encola
  `PUT /app/devices/current/push-token` (`{ push_token }`); al dar de baja el push se envía `null`.
- Topics de difusión: al iniciar sesión la app se suscribe a `role_<rol>` (p. ej. `role_chofer`) y, si
  el usuario tiene tienda, a `node_<id>`; al cerrar sesión se desuscribe.

## Estado del backend (2026-10-16)

- Hecho: `PUT /app/devices/current/push-token` y `FcmChannelSender::sendToDevice` (envío 1-a-1).
- Pendiente del backend: cablear el envío 1-a-1 al flujo de notificaciones y, si se usa difusión,
  publicar a los topics `role_<rol>` / `node_<id>` (la app ya está suscrita).
