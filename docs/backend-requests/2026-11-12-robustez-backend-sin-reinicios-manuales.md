# Requisito del dueño: backend sólido, sin reinicios/parches manuales como estrategia

**Fecha:** 2026-11-12 · **Tipo:** requisito de calidad (no feature) · **Lado:** backend/infra

## Contexto

Tras el incidente de staging del 2026-11-12 (toda petición autenticada en 500 por el `0A000`
"cached plan must not change result type" de PgBouncer tras una migración — ver
[`2026-11-12-staging-500-pgbouncer-cached-plan.md`](2026-11-12-staging-500-pgbouncer-cached-plan.md)),
el dueño fijó una directiva de fondo:

> "No es correcto estar haciendo cambios constantes o reinicios como solución en el servidor cloud. El
> backend tiene que ser **sólido** y estar preparado. Si con un cliente y un pedido se está cayendo, no sirve
> de nada. Si ese es su límite, hay un problema serio."

Aclaración técnica honesta: el incidente no fue por **carga** (no fue "un pedido" saturando el sistema), sino
por una **migración de esquema** que dejó al pooler sirviendo planes preparados viejos. Pero el principio del
dueño es válido y exigible: **un cambio de rutina no puede tumbar el servicio, y la solución no puede ser
entrar por SSH a reiniciar contenedores a mano.**

## Lo que el backend debe garantizar (estándar, no favor)

1. **Migraciones sin downtime.** Correr una migración jamás debe tumbar requests en vuelo.
2. **Config correcta por defecto en TODOS los entornos.** El `DB_EMULATE_PREPARES` (emular prepares cuando se
   habla con PgBouncer) debe ser el **default activo**, no depender de que alguien ponga una env. (El backend
   ya cambió el default para derivarlo de la infra — confirmar que va a producción.)
3. **Deploy con health/readiness gating.** El pipeline migra y verifica salud ANTES de dar por buena la
   versión; un boot roto (p. ej. el `TypeError` de `route:cache` visto en este reinicio) no debe quedar
   sirviendo.
4. **Auto-recuperación.** Un contenedor en mal estado se reinicia solo por healthcheck; el reinicio manual
   es emergencia, no estrategia.
5. **Producción blindada.** Esto ocurrió en staging; en producción debe ser **imposible**, no improbable.

## Pedido

Plan concreto por punto (y qué ya está cubierto) + confirmación de que el default de emulate-prepares llega a
producción. Transmitido en vivo a la sesión del backend (logistics-5b) el 2026-11-12.

## Respuesta del backend + decisiones del dueño (2026-11-12)

1. **Migraciones sin downtime — RESUELTO (código).** `config/database.php` emula prepares por DEFAULT cuando
   la app habla con PgBouncer (puerto 6432 / host `pgbouncer`) → SQL plano, sin plan cacheado en el backend:
   el `0A000` ya no puede ocurrir ni migrando en vivo. Además el DDL corre por conexión DIRECTA
   (`--database=pgsql_direct`, `DB_DIRECT_HOST=postgres`), no por el pooler.
2. **Config correcta por default — RESUELTO (código).** El default se DERIVA de la infra (no de una env); prod
   usa la misma convención `pgbouncer:6432` → aplica igual. Va a prod sin env a mano (al próximo redeploy con
   config refrescada).
3. **Deploy con health/readiness gating — PARCIAL.** Ya existe gating (`deploy.sh`: infra `--wait` → migra en
   contenedor efímero → `up --wait` → smoke a `/api/v1/health` exigiendo 200+`status:ok`). **Hueco:** el health
   solo probaba `postgis_version()`, no una tabla real (por eso dio 200 mientras `users` daba 500).
   **✅ DUEÑO APROBÓ (a):** el health hará además un `select 1 from <tabla real>` barato, para que una rotura de
   esquema/plan tumbe el health y falle el deploy. (También se arregló el `route:cache` TypeError de boot:
   el entrypoint limpia caches LOCALES antes de regenerarlos, sin `optimize:clear` para no vaciar el Valkey
   compartido.)
4. **Auto-recuperación — PARCIAL.** Hay `restart: unless-stopped` + healthchecks, pero el del `app` es
   `nc -z 9000` (solo "FPM acepta"), no readiness real → un server sirviendo 500 quedaba "verde".
   **✅ DUEÑO APROBÓ (b):** auto-reinicio atado al health REAL, con **umbral conservador** (N fallos sostenidos)
   para evitar restart-storms; separando readiness (saca de rotación) de liveness (reinicia). La defensa
   principal sigue siendo el fix 1; el auto-restart es defensa en profundidad.
5. **Producción blindada.** 1 y 2 van a prod por la convención de infra. Falta replicar en el pipeline de PROD:
   migrate por `pgsql_direct` + gating por smoke con el health nuevo (a) + el auto-restart (b). Objetivo del
   dueño: "imposible, no improbable".

El backend implementa (a) y (b) en código; **despliega el dueño** (el backend no toca staging/prod ni corre
gates). Pendiente: armar el checklist de verificación post-deploy.
