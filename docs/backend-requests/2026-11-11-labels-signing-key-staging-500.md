# CRÍTICO: emitir etiquetas tira 500 en staging (falta LABELS_SIGNING_KEY)

**Fecha:** 2026-11-11 · **Reportado por:** app (sesión `logistics-app-f4`) · **Backend:** sesión vigente
**Prioridad:** CRÍTICA (bloquea TODA emisión de etiquetas en staging para todos los roles)
**Estado:** pendiente en backend/ops

## Síntoma (app)

Al emitir etiquetas de un pedido (`POST /app/orders/{orderNumber}/labels`), la app muestra
**"Error del servidor"** (es un 5xx real, no bug de la app).

## Causa (log de staging, verificado)

```
RuntimeException: LABELS_SIGNING_KEY is not configured.
  Generate one with: php artisan logistics:labels:keygen
  en packages/logistics/labels/src/Infrastructure/Providers/LabelsServiceProvider.php:82
  LabelController.php:92  ·  userId 4 (preparador)  ·  channel staging
```

El contenedor `logistics-staging-app-1` no tiene seteada la variable **`LABELS_SIGNING_KEY`** (clave
Ed25519 para firmar las etiquetas). El provider la exige y lanza `RuntimeException` → 500 en cada emisión.

## Fix (backend/ops)

1. Generar la clave: `php artisan logistics:labels:keygen` (o el comando que corresponda) y setear
   `LABELS_SIGNING_KEY` en el entorno de **staging** (y confirmar que production la tenga también).
2. `php artisan config:clear && php artisan config:cache` y reiniciar el contenedor app/worker.
3. Verificar: `GET /app/labels/public-keys` debe devolver la clave pública, y `POST /app/orders/{n}/labels`
   debe emitir 200 en vez de 500.

## Nota para la app

Cuando esté la clave, la app ya valida las etiquetas offline (Ed25519) contra `GET /app/labels/public-keys`.
Si la clave de staging es NUEVA (distinta de la del vector de test), hay que regenerar
`test/fixtures/label_test_vector.json` desde el backend (ver CLAUDE.md "Etiquetas QR").
