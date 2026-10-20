# Pedido al backend: versión mínima de la app interna

**De:** app interna (logistics-app) · **Para:** agente/equipo del repo `logistics` (backend)
**Fecha:** 2026-10-16 · **Prioridad:** media (necesario antes del primer cambio de contrato incompatible)

## Problema

Las apps instaladas en los teléfonos de choferes y tiendas no se actualizan todas a la vez. Cuando el
contrato `/app/*` cambie de forma incompatible, una versión vieja puede mandar escaneos que el backend
rechace (y que la cola offline termine descartando). Hoy `openapi/v1.yaml` no tiene ningún mecanismo de
compatibilidad: no hay `/app/meta`, `/app/system` ni campo `min_app_version`.

## Lo que la app YA hace (desde esta versión)

1. **Envía en cada request `/app/*`:**
   - `X-App-Version: 1.4.2` (versión semántica de `pubspec.yaml`)
   - `X-App-Build: 42` (versionCode de Android)
2. **Lee de toda respuesta `/app/*` (2xx y errores) la cabecera `X-Min-App-Version`.** Si la versión
   instalada es menor, bloquea la app con la pantalla "Actualizá la app" (botón a la tienda/MDM).
3. **Trata `426 Upgrade Required` como bloqueo**, aunque no venga la cabecera.

Sin cambios en el backend nada se bloquea (ausencia de cabecera = sin mínima).

## Cambios pedidos

1. **Cabecera `X-Min-App-Version` en todas las respuestas `/app/*`** (middleware del grupo `/app`),
   también en errores 4xx/5xx y en `/app/auth/login`. Valor: `MAJOR.MINOR.PATCH` (p. ej. `1.4.0`).
   Configurable por entorno (setting o variable `APP_MIN_VERSION`), vacío/ausente = sin mínima.
   Exponerla en CORS (`Access-Control-Expose-Headers`) por si hay cliente web.
2. **Registrar `X-App-Version`/`X-App-Build`** en logs/telemetría del request (y opcionalmente en el
   dispositivo `/app/devices`) para saber qué versiones siguen en la calle antes de subir la mínima.
3. **Opcional — rechazo duro:** si `X-App-Version` < mínima en endpoints de escritura, responder
   `426 Upgrade Required` (RFC 7807, `type: .../upgrade-required`) en vez de procesar con un contrato
   viejo. Requests sin `X-App-Version` (versiones anteriores a esta) no deben rechazarse.
4. **Opcional — `GET /app/meta`** (sin auth) que devuelva:
   ```yaml
   AppMeta:
     type: object
     required: [min_app_version]
     properties:
       min_app_version: { type: string, example: "1.4.0" }
       latest_app_version: { type: string, nullable: true, example: "1.5.1" }
       update_url: { type: string, nullable: true, description: "Tienda/MDM; si viene, pisa APP_UPDATE_URL" }
   ```
   Útil para chequear al abrir la app antes del login. Si se agrega, documentarlo en
   `openapi/v1.yaml` y la app lo consume con el cliente generado.
5. **Documentar en `openapi/v1.yaml`** la cabecera de respuesta `X-Min-App-Version` (components/headers)
   y las de request `X-App-Version`/`X-App-Build`.

## Criterio de aceptación

- `curl -i .../api/v1/app/auth/me` devuelve `X-Min-App-Version` cuando la mínima está configurada.
- Con la mínima por encima de la instalada, la app muestra "Actualizá la app" en el siguiente request.
