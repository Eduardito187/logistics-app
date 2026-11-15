# Staging: 500 en TODA petición autenticada tras migraciones (PgBouncer "cached plan must not change result type")

**Fecha:** 2026-11-12 · **Severidad:** crítica (staging caído para la app) · **Lado:** backend/infra (NO app)

## Síntoma

El dueño marcó una entrega desde la app y le salió **"Error del servidor. Probá de nuevo en un momento."**
a pantalla completa (estado de error de `AsyncValueView`, icono de nube tachada + "Reintentar"). En la app
eso corresponde a un **5xx real** (`ApiException.isServerError`, status ≥ 500).

## Causa (confirmada en logs)

`docker logs logistics-staging-app-1`:

```
SQLSTATE[0A000]: Feature not supported: 7 ERROR:  cached plan must not change result type
(Connection: pgsql, Host: pgbouncer, Port: 6432, Database: logistics,
 SQL: select * from "users" where "users"."id" = 3 limit 1)
```

Revienta en el guard de **Sanctum** (`vendor/laravel/sanctum/src/Guard.php:130`) al cargar el usuario
autenticado, es decir **antes** de llegar a cualquier endpoint → **toda** petición autenticada da 500.

Es el problema conocido de **PgBouncer (transaction pooling) + prepared statements**: se corrieron
migraciones en staging (columnas nuevas: `pod_photo_pending`, `last_ip`, `vehicle_class`, etc.) y PgBouncer
sigue sirviendo **planes preparados cacheados** con el esquema viejo. Cuando una tabla cambia de forma, el
plan cacheado ya no coincide con el nuevo *result type* y Postgres tira `0A000`.

## Fix inmediato (levanta staging)

```
docker restart logistics-staging-app-1 logistics-staging-worker-1
# si persiste:
docker restart logistics-staging-pgbouncer-1
```

## Fix de fondo (que no se repita en cada migración)

Con PgBouncer en *transaction pooling*, desactivar prepared statements en la conexión `pgsql` de Laravel:
- `config/database.php` → conexión `pgsql` → `'options' => [PDO::ATTR_EMULATE_PREPARES => true]`, **o**
- Laravel 11: `'prepared_statements' => false`, **o** añadir `options=-c plan_cache_mode=force_custom_plan`
  al DSN.
- Alternativa: PgBouncer en *session pooling* (menos eficiente).

## Lado app (sin acción)

Correcto por diseño: el POD de la entrega se **encola** y un 5xx es **transitorio**
(`SyncRetryPolicy.isTransient` → reintenta), así que **la entrega no se pierde**; se sincroniza cuando el
backend vuelve. Para una **lectura**, la app muestra el error recuperable con "Reintentar". No hay cambio de
app pendiente por esto.
