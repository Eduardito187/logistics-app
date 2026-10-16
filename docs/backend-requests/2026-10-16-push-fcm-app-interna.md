# Pedido al backend: push FCM hacia la app interna

**De:** app interna (logistics-app) · **Para:** agente/equipo del repo `logistics` (backend)
**Fecha:** 2026-10-16

## Estado de la app

- La app recibe con Firebase Cloud Messaging
  (`firebase_messaging` 17) y solo espera las credenciales (`FIREBASE_*` en `config/*.json`).
- Ya consume el contrato nuevo: enum `Channel` con `FCM` y
  `NotificationView.fcm_topic`.
- Al tocar una notificación navega con `data.notification_id` (o `shipment_id`), igual que lo que
  publica `FcmChannelSender`.

## Qué falta del lado del backend

`FcmChannelSender` hoy publica **solo a topics** `shipment_<id>` (pensado para la app de clientes).
Para avisar a choferes / tienda / supervisor en la app interna hace falta:

1. **Destino por dispositivo.** La app manda en el login `device.push_token` = **Firebase
   Installation ID (FID)**, que es el identificador vigente en `firebase_messaging` 17
   (`register()` + `onRegistered`; `getToken()` quedó deprecado). Guardarlo por dispositivo
   (`push_token`, ya existe, `maxLength: 512` alcanza) y usarlo como destino de envío directo de
   FCM HTTP v1. Si el backend prefiere seguir con el *registration token* clásico, avisar y la app
   lo manda en su lugar (es un cambio de una línea en `PushService`).
2. **Actualizar el identificador sin re-login.** FCM puede rotarlo. Hoy solo viaja en el login y no
   hay endpoint para actualizarlo. Pedido: `PUT /app/devices/current/push-token`
   (body `{ "push_token": string|null }`, Bearer `/app/*`), y en `openapi/v1.yaml`.
   `null` = el dispositivo se dio de baja del push.
3. **(Opcional) Topics de la app interna** si se prefiere difusión por grupo, p. ej.
   `role_chofer`, `node_<id>` para una tienda. La app ya tiene `subscribeToTopic`; se suscribiría al
   iniciar sesión según `me.user.roles` / `me.user.node`.
4. **Payload:** mantener `notification` {title, body} + `data` {notification_id, shipment_id,
   message_type} como hoy; la app lo usa tal cual.
5. Mismo **proyecto de Firebase** para backend y app (`FCM_PROJECT_ID`).
