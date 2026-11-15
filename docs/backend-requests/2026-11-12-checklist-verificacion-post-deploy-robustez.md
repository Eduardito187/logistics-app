# Checklist de verificación post-deploy — robustez del backend

**Fecha:** 2026-11-12 · Acompaña a
[`2026-11-12-robustez-backend-sin-reinicios-manuales.md`](2026-11-12-robustez-backend-sin-reinicios-manuales.md).

Para correr **después de que el dueño redepliegue STAGING** con los cambios (a) health a tabla real y
(b) auto-restart conservador. Cada paso dice **quién** lo corre y si es **seguro** (solo lectura) o
**disruptivo** (rompe a propósito; solo con staging libre y OK del dueño).

Acceso: `ssh oci` (ver `.claude/memory/staging-server-access.md`; en Windows nativo, `wsl ssh oci ...`).

## 1. Deploy limpio (seguro)
- [ ] El deploy pasó el gating (smoke a `/api/v1/health` 200+`status:ok`). Si falló, NO quedó sirviendo.
- [ ] El sidecar de auto-heal está arriba y etiquetado: `ssh oci 'docker ps --format "{{.Names}} {{.Status}}"'`
      muestra el contenedor `autoheal`; `app` y `worker` tienen label `autoheal=true`
      (`docker inspect -f '{{index .Config.Labels "autoheal"}}' logistics-staging-app-1` → `true`).

## 2. Health dice la verdad (seguro)
- [ ] `ssh oci "docker inspect --format '{{json .State.Health}}' logistics-staging-app-1"` → `Status: healthy`.
- [ ] `curl -s http://137.131.245.152:8110/api/v1/health` → **200** con `status:ok` y
      `checks.schema: true` (además de `database` y `cache`). El `schema` es el que antes faltaba.

## 3. Camino autenticado real (seguro) — el que se caía
- [ ] Un flujo autenticado responde LIMPIO (el guard de Sanctum + `users` era lo que daba 0A000). Desde la
      app: login + abrir una pantalla que cargue datos. O por curl: login válido → `GET /app/auth/me` → 200.
- [ ] `ssh oci 'docker logs --since 10m logistics-staging-app-1 2>&1 | grep -c "0A000"'` → **0**.
- [ ] **App:** la entrega que quedó encolada durante el incidente ya sincronizó (reabrir la app / foreground).

## 4. Migración en vivo NO tumba nada (disruptivo leve — OK del dueño)
- [ ] Con la app sirviendo, correr una **migración aditiva de prueba** (por `pgsql_direct`) y confirmar
      **0 errores `0A000`** y que `/api/v1/health` sigue **200** durante y después. Es la prueba de fuego del
      fix 1: antes esto tumbaba todo.

## 5. Auto-heal reinicia SOLO tras el umbral (disruptivo — staging libre + OK del dueño)
- [ ] Forzar un fallo sostenido: `ssh oci 'docker stop logistics-staging-pgbouncer-1'` unos minutos.
- [ ] Observar: `/api/v1/health` pasa a **503** de inmediato (readiness: lo saca de rotación) pero el
      contenedor `app` **NO** se reinicia al instante.
- [ ] Recién tras el umbral conservador (~2,5 min: interval 30s × retries 5) `docker inspect` lo marca
      `unhealthy` y **autoheal** reinicia `app`/`worker` — no una persona por SSH.
- [ ] Levantar pgbouncer de nuevo: `ssh oci 'docker start logistics-staging-pgbouncer-1'`; health vuelve a 200.

## Banderas antes de llevar esto a PRODUCCIÓN (no bloquean staging)
- [ ] **autoheal monta `/var/run/docker.sock`** (control del daemon Docker). Aceptable en staging; **revisar/
      aislar** (o alternativa sin socket) antes de prod.
- [ ] **Pipeline de prod**: replicar migrate por `pgsql_direct` + gating por smoke con el health nuevo +
      apuntar el LB a `/health` (readiness real) + decisión final sobre autoheal/docker.sock.
- [ ] Recordar: la defensa **principal** es el fix 1 (emulate-prepares con PgBouncer → la falla no ocurre);
      el auto-restart es la **red**, no el plan.

## Archivos del backend (para trazabilidad)
`app/Support/Health/HealthProbe.php` (sonda única compartida), `HealthController.php`,
`app/Console/Commands/HealthCheckCommand.php`, `tests/Feature/HealthTest.php`, `openapi/v1.yaml`,
`.docker/compose/docker-compose.staging.yml`.
