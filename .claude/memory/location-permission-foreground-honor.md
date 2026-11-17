---
name: location-permission-foreground-honor
description: "nov 2026 (CRÍTICO) — el gate de ubicación exigía 'Permitir siempre' (background) y dejaba bloqueados a Honor/Magic OS y a quien concede 'mientras se usa la app'; ahora alcanza con PRIMER PLANO porque el rastreo corre con foreground service"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-16T21:25:49.472Z
---

**Bug crítico (reporte del dueño, Honor/Magic OS):** "no me lee que le di permiso de ubicación y siempre
me muestra la pantalla bloqueada". Causa: el gate (`LocationPermissionGate`) y el inicio del rastreo
(`TruckTrackingService._start`) exigían `ensureBackgroundPermission()` = `Permission.locationAlways`
(**ACCESS_BACKGROUND_LOCATION**, "Permitir siempre"). En Android 11+ ese permiso NO se concede por diálogo
(hay que ir a Ajustes y elegir "Permitir todo el tiempo"); en **Honor/Magic OS** la opción queda escondida
o se reporta como no concedida. El chofer daba "mientras se usa la app" (primer plano) y quedaba bloqueado.

**Fix (nov 2026):** exigir solo el permiso de **PRIMER PLANO** (`ensurePermission()` = `always` OR
`whileInUse` + GPS encendido). Es correcto: el rastreo corre con un **foreground service de tipo
`location`** (manifest ya tiene `FOREGROUND_SERVICE_LOCATION` + `foregroundServiceType="location"`), y un
FGS cuenta como "uso activo" → con primer plano alcanza para rastrear, incluida la app minimizada.
ACCESS_BACKGROUND_LOCATION solo haría falta para acceder al GPS desde el background SIN un FGS, que no es el
caso. Cambios: `location_permission_gate.dart` (`_check` → `ensurePermission`), `truck_tracking_service.dart`
(`_start` → `ensurePermission`), `location_required_view.dart` (texto: pide "Mientras se usa la app", no
"Permitir siempre"). `ensureBackgroundPermission()` queda en `LocationService` pero YA NO se usa para
gatear. Tests: los fakes de `location_permission_gate_test` y `truck_tracking_service_test` ahora
sobrescriben `ensurePermission` (el de `driver_test_support` ya lo hacía).

**Regla a futuro:** NO volver a exigir "Permitir siempre" para operar. Si alguna vez se necesita rastreo
con la app MUERTA (no solo minimizada), pedir background como mejora OPCIONAL, nunca bloqueante. Honor/Magic
OS además tiene matanza agresiva de procesos: el FGS lo mitiga, pero es tema aparte.

Ver [[windows-native-toolchain]], [[driver-fleet-ops-cycle]].
