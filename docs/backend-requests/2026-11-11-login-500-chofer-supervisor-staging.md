# Login 500 en staging para chofer y supervisor

**Fecha:** 2026-11-11
**Severidad:** ALTA — bloquea el login de los roles de campo clave (chofer/supervisor) en staging.
**Entorno:** staging `http://137.131.245.152:8110` (API `/api/v1`).
**Reporta:** app (logistics-app). El dueño lo probó en dispositivo real y ve "Error del servidor".

## Síntoma

`POST /api/v1/app/auth/login` devuelve **500** solo para **chofer** y **supervisor**;
los demás roles entran 200. La app muestra "Error del servidor" (es el 5xx real, no bug de la app).

## Repro (curl directo contra staging, password `password123`)

```
chofer@dismac.test        -> HTTP 500   ❌
supervisor@dismac.test    -> HTTP 500   ❌
tienda@dismac.test        -> HTTP 200   ✅
preparador@dismac.test    -> HTTP 200   ✅
transportista@dismac.test -> HTTP 200   ✅
admin@dismac.test         -> HTTP 200   ✅
```

Body del request (idéntico al de la app):
```json
{"email":"chofer@dismac.test","password":"password123",
 "device":{"fingerprint":"fp","platform":"android","name":"CPH2749"}}
```

Respuesta 500:
```json
{"type":"/problems/server_error","title":"Internal server error",
 "status":500,"code":"server_error","detail":"An unexpected error occurred.",
 "instance":"/api/v1/app/auth/login"}
```

(El 422 "device.fingerprint required" y "credentials do not match" funcionan bien;
el health `/api/v1/health` responde 200. O sea: server vivo, URL correcta.)

## Hipótesis

Los dos roles que fallan (chofer, supervisor) son los únicos atados a **datos de flota**
(vehículo/ruta/tripulación asignada). El resto no. Muy probablemente la construcción de la
respuesta de login (o un eager-load de la sesión) accede a una **relación nula** para estos
usuarios en staging: p. ej. `assigned_vehicle`, ruta/plan activo, o `crew` sin registro, y
tira un `Null`/relación inexistente → 500.

Sospechas concretas a revisar en el backend:
- El resource/transformer del login (`AppLoginResponse` / lo que arma `token`+`user`+perfil).
- Datos de staging incompletos: ¿corrió el seeder de flota en staging? Si chofer/supervisor
  no tienen vehículo/ruta sembrados, el código que asume que existen revienta.
- Revisar el log de Laravel de staging (`storage/logs/laravel.log`) con el timestamp del 500
  para el stack exacto.

## Qué necesita la app

Que `POST /app/auth/login` devuelva 200 (o un 4xx manejable) para chofer/supervisor, no 500.
Idealmente también sembrar en staging los mismos datos de flota que en dev (TodayScenarioSeeder
o equivalente), para poder probar el ciclo del chofer/supervisor de punta a punta.

Mientras tanto, en la app se puede entrar con tienda/preparador/transportista/admin.
