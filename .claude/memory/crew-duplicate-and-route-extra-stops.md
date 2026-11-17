---
name: crew-duplicate-and-route-extra-stops
description: "15-nov-2026 — dos bugs críticos del BACKEND vistos en staging: cambiar camión duplica la tripulación del día, y la ruta del chofer trae paradas ajenas al plan (31 en vez de 7); parche app + estado; preferencias de UI (botón principal fijo al pie, línea de tiempo en tarjetas)"
metadata:
  type: project
---

**Síntomas que reportó el dueño (staging, 2026-11-15):** al cambiarle el camión a un chofer la ficha seguía
mostrando el anterior y la actividad los dos; y al chofer le salía "Parada 2 de 31" sin haber entregado nada,
con solo 7 puntos en el mapa.

**Causa (leyendo la base de staging, solo lectura):** (1) `POST /app/fleet/crews` crea otra tripulación para
el mismo chofer y día en vez de reemplazar; (2) la ruta del día (`execution_driver_routes`) tenía 31 paradas:
las 7 del plan publicado + 24 pedidos viejos arrastrados SIN coordenadas, uno ya COMPLETED. La app solo
refleja esos datos (`RouteProgress` cuenta paradas; el mapa pinta las que tienen lat/lng).

**Estado al escribir esto:** el backend dejó los dos arreglos A MEDIO HACER y sin desplegar (el dueño pausó
esa sesión). Parche del lado app: al cambiar camión se borra la tripulación de HOY antes de armar la nueva
(`admin_staff_profile_screen.dart`), y ante un 409 (camión con otro chofer) se confirma y reintenta con
`replace: true`. La ruta de 31 paradas NO tiene arreglo en la app: hay que esperar al backend + saneo.
`route.updated` (canal del usuario) ya lo escucha `driverRouteProvider`, pero el backend aún no lo emite.

**Cómo diagnosticar algo así:** `ssh oci` + `docker exec logistics-staging-postgres-1 psql` con
`SET default_transaction_read_only = on` (tablas `fleet_crews`, `execution_driver_routes`,
`execution_driver_route_stops`, `planning_plans`). La base local de Docker NO es la que usa el teléfono.

**Preferencias de UI que fijó el dueño ese día:** el botón principal de una pantalla larga va FIJO al pie
(`bottomNavigationBar`), nunca al final del scroll; listas de paradas como LÍNEA DE TIEMPO en tarjetas, sin
recortar textos (nada de `ellipsis` en datos); el camión en mapas es el visto desde arriba del chofer
(también en flota). Ver [[planner-role-and-planning]], [[realtime-sockets-contract]].

**Flota en vivo:** el marcador de flota (`supervisor/.../truck_marker.dart`) envuelve al `TruckMarker` del
chofer (visto desde arriba, con rumbo `vehicle.heading`) y suma un punto verde/ámbar; marcador de 56 dp.
