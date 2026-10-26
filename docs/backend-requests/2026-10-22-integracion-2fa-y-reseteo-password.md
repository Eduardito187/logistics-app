# Prompt para la app Flutter — Integrar 2FA (TOTP / Google Authenticator) + reseteo de contraseña por OTP

**Para:** agente/dev de la app `logistics-app` (Flutter) · **Backend:** DisTrack (repo `logistics`).
Pegar este prompt tal cual. NO requiere cambios de backend: el contrato de abajo YA está implementado y
desplegado en la API. Base de la API: la misma que ya usa la app (`<API_BASE>/api/v1`). Todas las rutas de
auth viven bajo `<API_BASE>/api/v1/app/...`.

---

## Contexto y reglas

- La app ya hace login con `POST /app/auth/login`. Ahora hay que soportar un **segundo factor TOTP**
  (estándar RFC 6238, compatible con **Google Authenticator**, Authy, Microsoft Authenticator, etc.) y
  **reseteo de contraseña por código OTP de 6 dígitos** enviado por email.
- Todas las rutas autenticadas usan `Authorization: Bearer <token>` (token Sanctum que ya maneja la app).
- El 2FA es **opcional y por usuario**: un usuario sin 2FA sigue logueándose exactamente igual que hoy
  (el contrato del login NO cambió para ellos). Solo cambia si el usuario activó su 2FA.
- Errores: la API responde RFC 7807. En validaciones devuelve **HTTP 422** con cuerpo
  `{ "errors": { "<campo>": ["mensaje"] }, ... }`. Rate-limit excedido = **HTTP 429**. Credenciales malas = 401.
  La app debe leer `errors.<campo>[0]` para mostrar el mensaje (y manejar 429 con "intenta más tarde").

---

## 1) Login con posible reto de 2FA

`POST /app/auth/login`
Body (igual que hoy):
```json
{ "email": "...", "password": "...",
  "device": { "fingerprint": "<id-estable-del-dispositivo>", "platform": "android|ios", "name": "...", "push_token": "<FID opcional>" } }
```

La respuesta **200** ahora puede tener DOS formas — la app debe ramificar:

**A) Usuario SIN 2FA (igual que hoy):**
```json
{ "token": "...", "token_type": "Bearer", "expires_at": "2026-10-22T...Z",
  "user": { "id": "...", "name": "...", "email": "...", "roles": ["chofer"], "node": { ... | null } },
  "device": { "uuid": "...", "platform": "...", "name": "...", "last_seen_at": "..." } }
```
→ guardar token y entrar, como siempre.

**B) Usuario CON 2FA activo (nuevo):** NO trae token, trae un reto:
```json
{ "two_factor_required": true, "challenge_id": "<token-opaco>", "expires_in": 300 }
```
→ la app navega a una pantalla "Ingresa el código de tu app de autenticación", guarda `challenge_id`
(vive 5 min, un solo uso) y llama a `verify` (paso 2). NO reenvíes el `device` en verify.

`POST /app/auth/2fa/verify` (público)
```json
{ "challenge_id": "<el del login>", "code": "123456" }
```
- `code` acepta un **código TOTP de 6 dígitos** O un **recovery code** (formato `XXXX-XXXX`).
- **200** → MISMA forma que la respuesta A del login (`token`, `user`, `device`, …): guardar token y entrar.
- **422** → código o reto inválido/expirado (`errors.code` o `errors.challenge_id`). Si expiró, volver al login.
- Rate-limit: 10/min.

---

## 2) Activar 2FA (enrolamiento) — pantalla de seguridad en Ajustes

Requiere estar logueado (Bearer). Flujo enroll → mostrar QR/clave → confirm.

**Paso 1 — generar secreto:** `POST /app/auth/2fa/enroll` (sin body)
Respuesta **200**:
```json
{ "secret": "JBSWY3DPEHPK3PXP",
  "otpauth_uri": "otpauth://totp/DisTrack:usuario@dismac.test?secret=...&issuer=DisTrack&algorithm=SHA1&digits=6&period=30",
  "recovery_codes": ["ABCD-EFGH", "...", "... (8 en total)"] }
```
La app debe:
- **Mostrar el QR** generándolo localmente a partir de `otpauth_uri` (usar un paquete Flutter de QR, p.ej.
  `qr_flutter`; NO pidas la imagen al backend). El usuario lo escanea con Google Authenticator.
- **Mostrar también `secret`** como texto copiable ("o ingresa esta clave manualmente").
- **Mostrar los `recovery_codes`** una sola vez, con botón de copiar/guardar y aviso de guardarlos (sirven si
  pierde el teléfono; cada uno es de un solo uso).
- El 2FA NO queda activo hasta el paso 2.

**Paso 2 — confirmar:** `POST /app/auth/2fa/confirm`
```json
{ "code": "123456" }
```
- **200** `{ "message": "Two-factor authentication enabled." }` → 2FA activado. A partir de ahora el login
  pedirá el reto (sección 1-B).
- **422** `errors.code` → código inválido; dejar reintentar.

---

## 3) Desactivar 2FA

`POST /app/auth/2fa/disable` (Bearer). Reconfirmar identidad con **una** de las dos:
```json
{ "code": "123456" }        // TOTP o recovery code
// o
{ "password": "miClave" }   // la contraseña de la cuenta
```
- **200** `{ "message": "Two-factor authentication disabled." }`.
- **422** `errors.code` → no se pudo verificar la identidad.

---

## 4) Reseteo de contraseña por OTP (código de 6 dígitos por email)

Público (en la pantalla de login, enlace "¿Olvidaste tu contraseña?"). Dos pasos:

**Paso 1 — pedir el código:** `POST /app/auth/password/forgot`
```json
{ "email": "usuario@dismac.test" }
```
- SIEMPRE **200** `{ "message": "If the account exists, a reset code has been sent to the email." }`
  (no revela si el email existe → mostrar ese mensaje genérico y avanzar al paso 2). Rate-limit 5/min.

**Paso 2 — resetear con el código:** `POST /app/auth/password/reset`
```json
{ "email": "usuario@dismac.test", "code": "123456", "password": "nuevaClave8+" }
```
- `password` mínimo 8 caracteres (validar en la app antes de enviar).
- **200** `{ "message": "Password has been reset." }` → mandar al login.
- **422** `errors.code` → código inválido o expirado (expira a los 10 min); `errors.password` si no cumple.
- Rate-limit 10/min.

---

## UX / pantallas a implementar en la app

1. **Login**: tras `login`, si la respuesta trae `two_factor_required` → pantalla de código 2FA (campo de 6
   dígitos + enlace "usar un código de recuperación"); al éxito de `verify`, entrar.
2. **Ajustes › Seguridad › Autenticación en dos pasos**: estado (activado/desactivado), botón "Activar"
   (flujo enroll→QR+clave+recovery→confirm) y "Desactivar".
3. **¿Olvidaste tu contraseña?** (desde login): email → código + nueva contraseña.
4. Textos en español, claros y generales (es personal de campo). Manejar 422 (mostrar `errors.*`), 429
   ("demasiados intentos, espera un momento") y expiración del reto/código (volver a empezar).

## Detalles técnicos

- **QR**: solo client-side desde `otpauth_uri` (paquete QR de Flutter). El backend no entrega imagen de QR.
- **TOTP**: SHA1, 6 dígitos, período 30s (ya viene en el `otpauth_uri`); cualquier app de autenticación estándar sirve.
- **Token/sesión**: igual que hoy (Bearer en almacenamiento seguro; logout `POST /app/auth/logout`;
  refresh `POST /app/auth/refresh`). El `challenge_id` es efímero (5 min, un solo uso) y NO es un token de sesión.
- **Device**: el `device.fingerprint` del login se reutiliza del reto; en `verify` NO se reenvía.
- No hay flag de "2FA activo" en `GET /app/auth/me` (devuelve id/name/email/roles/node). La app deduce el
  estado por el resultado de enroll/confirm/disable, o guarda un flag local. (Si se quisiera, el backend puede
  agregar `two_factor_enabled` a `/me` — pedirlo aparte; no es necesario para que funcione.)

## Para validar (end-to-end, cuando el backend esté arriba)

1. Usuario de prueba sin 2FA: login normal (respuesta A) → entra directo.
2. Activar 2FA: enroll → escanear QR con Google Authenticator → confirm con el código → 200.
3. Logout y volver a loguear: ahora `login` devuelve `two_factor_required` → `verify` con el código de la
   app → entra. Probar también con un recovery code.
4. Desactivar 2FA con código o contraseña → login vuelve a ser directo.
5. Reseteo: "olvidé contraseña" → recibir el código por email → resetear → loguear con la nueva.
   (En backend dev, el código llega a `storage/logs/laravel.log` si `MAIL_MAILER=log`.)

Cuentas de prueba (backend): `*@dismac.test` / `password123` (admin, supervisor, chofer, preparador, tienda, transportista).
