---
name: staging-login-500-2fa-appkey
description: "App mostraba 'Error del servidor' en login: era un 500 REAL del backend de staging para chofer/supervisor por secreto 2FA cifrado con APP_KEY viejo (DecryptException). Cómo se diagnostica y arregla."
metadata:
  node_type: memory
  type: reference
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-11T16:47:00.527Z
---

Nov 2026. El dueño reportó que la app no entraba en staging: **"Error del servidor"** al dar login. NO era
la app ni el endpoint — era un **500 real del backend** para ciertos usuarios.

**Diagnóstico (reusable para cualquier "error de servidor" de la app):**
1. "Error del servidor" sale de `api_exception.dart` SOLO con **HTTP ≥ 500** (`isServerError`). Si aparece,
   sospechar del backend, no de la app.
2. `curl` directo al endpoint por rol (usuarios de prueba `password123`, ver [[dev-test-users-scenario]]):
   - **chofer y supervisor → 500**; tienda/preparador/transportista/admin → 200.
3. Localizar pre/post-auth: chofer con password MALO → **422** (auth OK); con password BUENO → **500** ⇒ el
   500 es al **armar la respuesta de login**, después de autenticar.
4. Leer el log del contenedor ([[staging-server-access]]): `DecryptException: The MAC is invalid` en
   `app/Models/User.php` (cast `encrypted`) ← `AuthController::twoFactorIsEnabled()` al leer
   `app_authentication_secret`.

**Causa raíz:** el `app_authentication_secret` (cast `encrypted`, TOTP 2FA) de chofer/supervisor fue cifrado
con un **APP_KEY distinto** al de staging (base sembrada/copiada de otro entorno, o APP_KEY rotado). Staging
no lo puede desencriptar → login revienta. Los roles sin 2FA entran bien.

**Fix (data; el secreto es irrecuperable con la key actual):** limpiar el 2FA corrupto —
`app_authentication_secret`, `app_authentication_recovery_codes`, `two_factor_confirmed_at` = NULL — para los
afectados (o para todos los `whereNotNull('app_authentication_secret')` cuyo `decrypt()` tire). Pueden
reinscribir 2FA después. SQL por psql o tinker en el contenedor app ([[staging-server-access]]).

**Fix de fondo (pedido al backend, `docs/backend-requests/2026-11-11-login-500-chofer-supervisor-staging.md`):**
no copiar secretos 2FA entre entornos, y/o que el login **tolere un secreto indescifrable** tratándolo como
"sin 2FA" en vez de 500.

**Fix de la app (lado cosmético, YA hecho):** en `login_screen.dart`, al tocar el botón se hace
`ScaffoldMessenger.clearSnackBars()` ANTES de enviar — antes el aviso de error viejo (dura 4 s) quedaba
visible mientras volaba el request y se veían "dos errores" (el viejo y el nuevo). Ver [[product-ux-decisions]].

**Otro 500 de staging (11-nov): emitir etiquetas.** `POST /app/orders/{n}/labels` → 500 `RuntimeException: LABELS_SIGNING_KEY is not configured` (LabelsServiceProvider.php:82). Falta la env de la clave de firma Ed25519 en el contenedor app de staging. Es backend/ops: `php artisan logistics:labels:keygen` + setear LABELS_SIGNING_KEY. Derivado a logistics-2d + `docs/backend-requests/2026-11-11-labels-signing-key-staging-500.md`.
