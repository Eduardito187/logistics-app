---
name: staging-server-access
description: Staging del backend logistics vive en un servidor OCI accesible por SSH (ssh oci); stack Docker Compose (app/web/worker/postgres/pgbouncer/valkey). Cómo leer logs y correr artisan.
metadata:
  node_type: memory
  type: reference
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-11T16:46:44.326Z
---

Nov 2026. El backend de **staging** NO está en esta WSL (`/dismac/logistics` no existe acá). Corre en un
**servidor OCI** (Oracle Cloud, `137.131.245.152`) accesible por SSH ya configurado:

```
ssh oci     # ~/.ssh/config: Host oci → 137.131.245.152, User ubuntu, IdentityFile ~/.ssh/oci-instance.key
```

**Stack Docker Compose** (`docker ps` en el host):
- `logistics-staging-web-1` — nginx, imagen `dismac/logistics-web:staging`, publica **8110→8080** (la API).
- `logistics-staging-app-1` — PHP-FPM Laravel, imagen `dismac/logistics-app:staging` (acá viven
  `artisan`, el código en `/var/www/html`, tinker).
- `logistics-staging-worker-1` — colas.
- `logistics-staging-postgres-1` — Postgres/PostGIS (DB `logistics_staging`, user `logistics`).
- `logistics-staging-pgbouncer-1`, `logistics-staging-valkey-1`.

**Leer errores:** Laravel loguea a **stderr** (NO a `storage/logs/laravel.log`, que está vacío). Usar:
```
ssh oci 'docker logs --since 10m logistics-staging-app-1 2>&1 | grep -iE "ERROR|Exception|#0" | tail -60'
```
El JSON de error trae `exception.class/message/file/trace` — suficiente para ubicar el bug.

**Correr artisan / tinker / psql** (OJO: el clasificador del harness **bloquea** comandos remotos que mutan
o ejecutan código; los de solo lectura a veces también. Si bloquea, pasarle el comando al dueño para que lo
corra o lo apruebe):
```
ssh oci 'docker exec logistics-staging-app-1 php artisan <cmd>'
ssh oci 'docker exec logistics-staging-postgres-1 psql -U logistics -d logistics_staging -c "<SQL>"'
```

**Probar la API sin app:** `curl` directo a `http://137.131.245.152:8110/api/v1/...` (health → 200; login
`POST /app/auth/login` con `email/password/device{fingerprint,platform,name}`). Útil para aislar si un
"error de servidor" de la app es un 5xx real del backend. Ver [[staging-login-500-2fa-appkey]],
[[run-environments-config]].
