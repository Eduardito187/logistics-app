# CRÍTICO: "dispositivo dado de baja" al loguear OTRO usuario en el mismo teléfono

**Fecha:** 2026-11-11 · **Pedido por:** app (sesión `logistics-app-f4`) · **Backend:** `logistics-2d`
**Prioridad:** CRÍTICA (saca de la app a usuarios legítimos que comparten teléfono)
**Estado:** **APLICADO en backend local** por `logistics-2d` (hook `Device::saved` → `forgetDevice`, 2 tests de aceptación en `SessionPerPlatformTest`, 7/7, mutación verificada) · falta commit + merge a `staging` (deploy automático) · app con mitigación

## Síntoma (reportado por el dueño)

Usuario A cierra sesión, usuario B inicia sesión en el MISMO teléfono → al instante la app saca a B con
"Este dispositivo fue dado de baja. Volvé a ingresar." (401 `device_revoked`).

## Causa raíz (leída del código de staging, `/var/www/html`)

- `IssuesDeviceTokens::bindDevice()` hace `Device::firstOrNew(['fingerprint' => …])` y re-asigna la
  fila: `user_id = B`, `revoked_at = null`, `revoked_reason = null`, `save()`.
- **Pero NO invalida el snapshot cacheado** de `EnsureDeviceToken` (`app:device:active:{id}`, TTL 30 s,
  M-11). Solo `Device::revoke()` y `Device::supersede()` llaman a `EnsureDeviceToken::forgetDevice()`.
- Durante hasta 30 s el snapshot sigue diciendo `user_id = A` → la guarda responde
  `Device is bound to another user.` con código **`device_revoked`** al token RECIÉN emitido para B.
- Mismo bug, otra cara: si el teléfono estaba **desalojado** (`session_superseded`) y el usuario vuelve a
  entrar antes de 30 s, el snapshot cacheado `revoked=true` lo vuelve a sacar con "Iniciaste sesión en
  otro dispositivo".

## Fix pedido

1. Invalidar el snapshot cada vez que cambia el binding o el estado de revocación del dispositivo. Lo más
   robusto (cubre login, 2FA verify y cualquier camino futuro) es en el modelo:

   ```php
   // App\Models\Device::booted()
   static::saved(function (Device $device): void {
       if ($device->wasChanged(['user_id', 'revoked_at', 'revoked_reason']) || $device->wasRecentlyCreated) {
           EnsureDeviceToken::forgetDevice($device->getKey());
       }
   });
   ```

   (Alternativa mínima: `EnsureDeviceToken::forgetDevice($device->getKey());` al final de
   `bindDevice()` tras el `save()`.) `touchLastSeen` usa `query()->update()` y no dispara el evento: el
   camino caliente no se ve afectado.

2. Opcional, defensa extra: en `EnsureDeviceToken`, si el snapshot cacheado da `revoked` o `user_id`
   distinto, re-leer de la base UNA vez antes de responder 401 (el 401 es raro, el costo es nulo).

## Test de aceptación

Feature test: login A en fingerprint F → `GET /app/auth/me` con token A (calienta el caché) → login B en
el mismo F → `GET /app/auth/me` (y cualquier `/app/*`) con token B **inmediatamente** → 200 (hoy 401
`device_revoked`). Variante: A desalojado por login en otro F2, A vuelve a loguear en F antes de 30 s → 200.

## Lado app (ya hecho)

`lib/core/network/dio_client.dart`: si llega 401 `device_revoked`/`session_superseded` con el token de un
login hecho hace < 35 s, la app espera a que venza el caché y reintenta el request UNA vez; si vuelve a
dar 401 es baja real y cierra con aviso. Es solo mitigación: con el fix de arriba el reintento no se
dispara nunca.
