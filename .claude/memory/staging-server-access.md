---
name: staging-server-access
description: Staging del backend logistics vive en un servidor OCI accesible por SSH (ssh oci); stack Docker Compose (app/web/worker/postgres/pgbouncer/valkey). Cómo leer logs y correr artisan.
metadata:
  node_type: memory
  type: reference
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-13T18:47:31.235Z
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
- `logistics-staging-postgres-1` — Postgres/PostGIS (DB **`logistics`**, user `logistics` — el
  `DB_DATABASE` real es `logistics`, NO `logistics_staging`; verificado con `printenv DB_DATABASE`).
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
ssh oci 'docker exec logistics-staging-postgres-1 psql -U logistics -d logistics -c "<SQL>"'
```
(nov 2026: `docker exec … psql`/`php artisan schedule:clear-cache` corrieron OK desde esta sesión.)

**Probar la API sin app:** `curl` directo a `http://137.131.245.152:8110/api/v1/...` (health → 200; login
`POST /app/auth/login` con `email/password/device{fingerprint,platform,name}`). Útil para aislar si un
"error de servidor" de la app es un 5xx real del backend. Ver [[staging-login-500-2fa-appkey]],
[[run-environments-config]].

**Portabilidad / otras sesiones (importante).** Esta memoria viaja en el espejo del repo (`.claude/memory/`),
así que CUALQUIER sesión de Claude la lee. Pero **el acceso real NO viaja**: el alias `oci` y la llave privada
`~/.ssh/oci-instance.key` viven solo en el `~/.ssh` de ESTA WSL (secretos de la máquina, fuera de git, y así
debe ser). Para que otra sesión/máquina pueda entrar necesita que el dueño le ponga localmente: (1) la llave
privada en `~/.ssh/oci-instance.key` (permisos 600) y (2) el bloque en `~/.ssh/config`
(`Host oci` → `HostName 137.131.245.152`, `User ubuntu`, `IdentityFile ~/.ssh/oci-instance.key`). **Windows nativo (habilitado nov 2026):** `ssh oci` ya funciona **directo** desde Git Bash Y PowerShell de
Windows (no hace falta `wsl ssh oci`). Se replicó: la llave en `C:\Users\ehhuallata\.ssh\oci-instance.key`
(copiada de WSL; permisos restringidos con `icacls <key> /inheritance:r /grant:r "$env:USERNAME:R"` — OpenSSH
rechaza llaves con permisos abiertos) y el bloque `Host oci` en `C:\Users\ehhuallata\.ssh\config` (ssh lee
`config`, NO `config.txt`; se agregó también el bloque de bitbucket para no perderlo). Se omiten
`ControlMaster/ControlPath` (OpenSSH de Windows no los soporta bien). Sale un WARNING de "post-quantum key
exchange" — es solo aviso del server viejo, no un error. Desde WSL sigue igual: `ssh oci`. **No hay password
en texto plano**: acceso por llave SSH; la DB tampoco expone password (user `logistics` / DB `logistics`).
