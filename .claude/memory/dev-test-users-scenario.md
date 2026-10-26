---
name: dev-test-users-scenario
description: Usuarios de prueba por rol (password123) y el seeder TodayScenarioSeeder que arma el día en Santa Cruz en el backend dev
metadata:
  node_type: memory
  type: reference
  originSessionId: 22a12647-3b3a-43c2-a3c3-8f46fc627148
  modified: 2026-10-26T04:19:24.292Z
---

Backend dev (WSL `/dismac/logistics`, API `http://localhost:8110/api/v1`; desde el emulador `http://10.0.2.2:8110`). Todas las cuentas con contraseña **`password123`** (solo dev):

| Email | Rol | Qué ve |
|---|---|---|
| admin@dismac.test | admin | solo admin web (Filament); NO entra a la app de campo |
| chofer@dismac.test | chofer | conductor "Iker Corona", camión **904U10**, ruta del día en curso |
| tienda@dismac.test | tienda | nodo T-SCZ-01 "Tienda Santa Cruz Norte": recepción abierta + recojo listo |
| supervisor@dismac.test | supervisor | flota en vivo (904U10 en SCZ), planes, alertas |
| preparador@dismac.test | preparador | envíos del día |
| transportista@dismac.test | transportista | solo el rol, sin datos propios |

No existe usuario ayudante (los ayudantes son registros de flota sin cuenta).

**Datos del día:** `database/seeders/TodayScenarioSeeder.php` (idempotente, solo local/dev, ids `SCZ-AAMMDD-NN` con la fecha → re-correrlo otro día arma ESE día). Re-correr desde `/dismac/logistics`:
`docker compose exec -T app php artisan db:seed --class='Database\Seeders\TodayScenarioSeeder'`
Arma tripulación + plan publicado (7 paradas en SCZ con geometría por calles) + ruta IN_PROGRESS (2 entregadas, `current_stop` = 3) + recepciones de tienda + telemetría. Sin `LABELS_SIGNING_KEY` en `.env` no emite etiquetas QR (`php artisan logistics:labels:keygen`).

Login de la app manda `device: {fingerprint, platform, name}` (sin eso → 422). Planes viejos sin geometría: `php artisan logistics:planning:backfill-geometry`.

**Why:** el dueño pidió tener las credenciales de prueba a mano y datos "de hoy" para probar la app.
**How to apply:** para probar por rol usar estas cuentas; si "no hay asignación/ruta" en un día nuevo, re-correr el seeder. Ver [[run-environments-config]] y [[app-api-coverage-state]].
