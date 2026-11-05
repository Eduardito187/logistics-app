# Sesiones estilo banco: 1 web + 1 app (una por plataforma), nuevo dispositivo cierra el anterior

- **De:** app (logistics-app) — por pedido del dueño
- **Para:** backend (logistics) — sesión `logistics-8e`
- **Fecha:** 2026-11-05
- **Prioridad:** Alta
- **Estado:** Delegado al backend.

## Regla (como apps de banco)

- **Máximo 2 sesiones activas por usuario: 1 `web` + 1 `app`.** Nunca 2 web ni 2 app.
- **Web y app coexisten:** iniciar sesión en la web teniendo sesión en la app NO cierra la app, y
  viceversa.
- **Un segundo dispositivo del MISMO tipo cierra el anterior:** si ya hay sesión `app` en el teléfono A y
  se inicia sesión `app` en el teléfono B, la del teléfono A **se cierra** y solo queda la de B. Igual para
  web.

## Qué manda hoy la app

Login `POST /app/auth/login` con `{ email, password, device: { fingerprint, name, platform } }`
(`platform` = `android | ios`). Hay flujo global de **401 → logout** (`_AuthInterceptor` en
`dio_client.dart`) que ya excluye `/login`, `/token`, `/auth/me`.

## Lo que debe implementar el BACKEND (exigente, DoD verde)

1. **Bucket de sesión por plataforma:** `web` vs `app` (agrupar `android`+`ios` como `app`). Derivarlo del
   `device.platform` del login, o de un campo explícito `client_kind` (si lo preferís, la app lo manda —
   ver abajo).
2. **Invariante:** a lo sumo **1 sesión activa por bucket por usuario**. En cada login exitoso:
   - Revocar/invalidar la sesión (y su token) existente del **MISMO bucket** del usuario.
   - **No tocar** la sesión del otro bucket.
   - Si el `device.fingerprint` es el mismo (reingreso del mismo dispositivo), es reemplazo natural (sigue
     siendo 1 sesión del bucket).
3. **Dispositivo desalojado → 401 con código distinguible:** cuando el dispositivo viejo use su token
   revocado, responder `401` con un **código específico** (p. ej. `session_superseded`), distinto del
   expirado normal, para que la app muestre "Iniciaste sesión en otro dispositivo" y cierre sesión.
4. **(Opcional, mejor UX) desalojo inmediato:** push silencioso (FCM, ya integrado) al dispositivo
   desalojado para que cierre al instante sin esperar al próximo request. Baseline = 401 al próximo
   request.
5. **openapi aditivo:** documentar `client_kind` (si aplica), el código de error `session_superseded`, y
   el comportamiento de una-sesión-por-plataforma.

## Lo que hará la app (cuando el contrato esté)

- Mandar `client_kind: "app"` explícito en el login si el backend lo pide (o dejar que derive de
  `platform`). **Decime cuál preferís.**
- En `401` con `session_superseded`: cerrar sesión y mostrar un aviso claro ("Tu sesión se cerró porque
  iniciaste sesión en otro dispositivo"), distinto del "tu sesión expiró" normal.
- Si mandás push silencioso de desalojo, lo manejo para cerrar al instante.

## Criterio de aceptación

Un usuario puede tener exactamente 1 sesión `web` + 1 `app` a la vez; un segundo login del mismo bucket
revoca el anterior (el token viejo da 401 `session_superseded`); web y app no se afectan entre sí. DoD
verde (tests, PHPStan, Pint) + openapi actualizado.

## Pregunta al backend (bloqueante para el cableado app)

¿La app manda `client_kind` explícito, o derivás el bucket de `device.platform`? Y confirmá el **código
de error** exacto del 401 por desalojo.
