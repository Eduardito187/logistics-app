---
name: device-revoked-other-user-cache
description: "Dispositivo dado de baja" al loguear OTRO usuario en el mismo teléfono = caché 30 s del backend (EnsureDeviceToken) que bindDevice no invalidaba; fix backend + mitigación app (reintento 35 s)
metadata:
  type: project
---

Nov 2026 (crítico, reportado por el dueño). Usuario A cierra sesión, B entra en el MISMO teléfono → la app saca a B con "Este dispositivo fue dado de baja" (401 `device_revoked`).

**Causa (backend):** `EnsureDeviceToken` cachea 30 s (`app:device:active:{id}`) el snapshot `user_id/revoked`; `IssuesDeviceTokens::bindDevice()` re-asigna la fila Device (mismo fingerprint) al usuario nuevo SIN `forgetDevice()` → "Device is bound to another user" con el token recién emitido. Misma raíz: re-login antes de 30 s tras un desalojo → `session_superseded` falso.

**Fix backend:** `logistics-2d` agregó hook `Device::saved` → `forgetDevice` (+2 tests en `SessionPerPlatformTest`). El 2026-11-11 quedó SIN commit/deploy (staging se despliega solo al mergear a la rama `staging`). Doc: `docs/backend-requests/2026-11-11-device-cache-otro-usuario.md`.

**Mitigación app:** `dio_client.dart` `_retryAfterFreshLogin`: 401 `device_revoked`/`session_superseded` con el token de un login real hecho hace < `kDeviceBindingGrace` (35 s, `deviceBindingGraceProvider`) → espera a que venza el caché y reintenta UNA vez (`extra['deviceBindingRetried']`); si vuelve 401 cierra normal. `SessionNotifier.freshSignInAt` (solo `signIn`; null en restore/signOut).

**How to apply:** si reaparece "dado de baja"/"otro dispositivo" justo tras loguear, mirar primero si el fix del backend está desplegado en staging. El backend local de WSL (`~/dismac/logistics`) está viejo (13-oct); el código vigente se lee en el contenedor de staging (ver [[staging-server-access]]).

**Fix definitivo en la app (11-nov, 2da ronda):** el dueño siguió viéndolo (backend sin deploy + APK sin la mitigación; tardaba ~10 reintentos ≈ 30 s). Ahora `device.fingerprint` = `userDeviceFingerprint(installId, email)` (`lib/core/auth/device_fingerprint.dart`: `<installId>-u<16 hex sha256>`): UNA fila `devices` por instalación+usuario → cambiar de usuario ya no reasigna nada y el caché no puede quedar desfasado. `X-Device-Id` sigue siendo el installId (el backend no lo usa). Efecto: la fila vieja compartida queda y se desaloja sola al próximo login del mismo usuario.
