# Seguimiento del chofer: no se genera la ruta del viaje ni el reruteo por desvío

**Fecha:** 2026-11-16 · **Pide:** app (logistics-app-98) · **Para:** backend (logistics-e8)
**Prioridad:** Alta · bug de terreno (el dueño lo vio en el teléfono)

## Síntoma (foto del dueño)

En "Entrega en curso": "Parada 5 de 6 · Sin hora estimada · Faltan 768 km · 30 h 42 min", el camión en
Santa Cruz y el destino en La Paz, **sin trazo de ruta dibujado**. Dos fallas:

1. **No se generó la ruta del viaje** (el trazo por calles). El mapa cae a línea recta y la distancia sale
   descomunal (768 km en recta).
2. **El reruteo al salirse del camino no funciona**: cuando el camión se desvía, no se detecta ni se
   recalcula la ruta.

## Diagnóstico (leído en el código del backend, solo lectura)

`GetDriverRouteHandler` arma la respuesta con dos piezas que hoy llegan **null**:

- **`route_geometry`** = `RouteGeometryReader->forVehicleAndDate(vehicle, date)` → la **geometría del
  plan**. Si el plan no tiene geometría calculada (o las paradas no están geocodificadas), llega null y la
  app no tiene trazo que dibujar. (`openapi`: "computed on the fly if the plan still lacks it … Null only
  when fewer than two stops have coordinates" → en la práctica está llegando null.)
- **`off_route` / `reroute_geometry`** = `LiveRouteStateReader->forVehicle(...)`, o sea el **motor de ETA en
  vivo** (`OffRouteEvaluator` + `RerouteGeometryCalculator`, paquete telemetry). El handler dice: *"Null si
  el motor no está disponible; entonces cada parada conserva su ETA planificada."* → si el motor no corre o
  no hay posiciones del vehículo, nunca hay `off_route` ni `reroute_geometry`.

Es decir: la maquinaria EXISTE pero no está produciendo salida en staging/prod. Esto es
**backend/infra**, no la app (la app no puede calcular rutas por calles ni desvíos; solo dibuja lo que el
backend manda).

## Lo que YA hizo la app de su lado (desplegable hoy, mitiga el síntoma)

- **Respaldo de trazo sin geometría del plan:** si `route_geometry` es null, el mapa ahora dibuja una
  **línea que une las paradas en orden de secuencia** (las que tienen coordenadas), para que "la ruta del
  viaje" siempre se vea como un recorrido que conecta las paradas. (No reemplaza el trazo por calles, es un
  respaldo visual.)
- **Dibuja el reruteo:** cuando el backend manda `off_route=true`, el mapa pinta el **`reroute_geometry`**
  (ámbar, camión → próxima parada). Si el backend aún no lo manda, la app detecta el desvío **localmente**
  (distancia del camión al trazo por calles > 150 m) y dibuja una línea directa camión → destino como
  reconexión provisional. La tarjeta ya mostraba la pastilla "Fuera de ruta".

→ Con esto, apenas el backend empiece a mandar `route_geometry` y `off_route/reroute_geometry`, el mapa los
usa (prioriza siempre la verdad del backend). Pero el trazo REAL por calles y la detección robusta de
desvío (con histéresis, la que ve el supervisor) **dependen del backend**.

## Lo que necesita del backend

1. **`route_geometry` no nula cuando la ruta tiene ≥2 paradas con coordenadas.** Confirmar/arreglar:
   (a) que al **publicar un plan** se calcule y persista su geometría (`PlanGeometryRefresh` corre y OSRM/el
   motor de ruteo está accesible); (b) que las paradas estén **geocodificadas** (lat/lng pobladas desde el
   ingest/SAP). Hoy, con 6 paradas, llega null → algo de esto falla.
2. **Motor de ETA en vivo produciendo estado** para el vehículo con ruta abierta: que el job
   `RefreshVehicleEtas` corra en el scheduler de staging/prod y que las **posiciones del vehículo** estén
   entrando (la app las manda por `POST /tracking/.../position`). Sin posiciones no hay `off_route` ni
   `reroute_geometry`. Confirmar que el `LiveRouteStateReader` devuelve estado (no null) cuando el camión
   está en ruta y reportando GPS.
3. **Datos de prueba creíbles:** en el `TodayScenarioSeeder`, que el camión y sus paradas estén en la
   **misma ciudad** (hoy el camión aparece en Santa Cruz y una parada en La Paz → 768 km). Eso además
   confunde el encuadre del mapa.

## Aparte: bloqueo por inspección pre-salida (pre-check)

El dueño pidió que **si falta el checklist pre-salida, el chofer NO pueda iniciar las entregas** de esa
salida. **App hecha:** la barra de acciones de la entrega en curso se reemplaza por "Hacer inspección
pre-salida" cuando `inspectionForCurrentRoute` (por ruta, o diario con backend viejo) da pendiente;
fail-open solo si no se sabe. **Pedido al backend (defensa en profundidad):** rechazar el POD/entrega
(`store-drop`/`deliveries`) con 409/422 si la ruta/salida no tiene el checklist pre-salida cumplido
(análogo a `fit_to_dispatch`/UnfitVehicleDispatch), para que no dependa solo del cliente. Confirmar si ya
existe esa precondición o si hay que agregarla.

## Re-test del dueño (2026-11-17, DESPUÉS del deploy)

El dueño volvió a probar en el teléfono tras publicar el backend y el reruteo **sigue sin salir**: se
desvió de lo mapeado y **nunca apareció ninguna sugerencia ni corrección de ruta**. Dato clave que aporta:
*"la distancia contabilizaba que me estaba yendo en contra ruta, los km se sumaban porque me desviaba"* →
o sea **las posiciones SÍ están entrando** (el sistema lo sigue punto a punto, por eso acumula km del
desvío), pero el motor **no emite `off_route` ni `reroute_geometry`**. Esto descarta "faltan posiciones" y
apunta a que el job de ETA/off-route **no corre** (scheduler) o el `OffRouteEvaluator`/
`RerouteGeometryCalculator` no se dispara con las posiciones que ya llegan.

Pedido concreto para cerrar esto (no es de la app — verificado de nuevo hoy, ver abajo):
1. Confirmar que **`RefreshVehicleEtas` (o el job equivalente) está en el scheduler de staging y corriendo**
   (cron activo, no solo definido). Un `off_route_since` que nunca se setea = el evaluador no se ejecuta.
2. Confirmar que el `OffRouteEvaluator` compara la **última posición ingerida** contra la geometría del
   plan y persiste `off_route=true` + `reroute_geometry` (OSRM: posición actual → próxima parada) cuando el
   desvío supera el umbral con histéresis. Si OSRM no está accesible desde el worker, ese es el bloqueo.
3. Como el dueño confirma que los km del desvío se acumulan: exponer, si existe, **distancia recorrida real
   vs. distancia planificada** por ruta (para que el chofer/supervisor vean el sobre-recorrido); si no
   existe, es opcional, pero el dato ya está (se deriva de las posiciones ingeridas).

**La app NO cambia:** re-verificado hoy en el código — ya consume `off_route`/`off_route_since`/
`reroute_geometry` (mapa + pastilla "Fuera de ruta"), y cuando el backend no manda nada, detecta el desvío
localmente (>150 m del trazo por calles) **siempre que `route_geometry` venga con trazo real** y dibuja una
reconexión provisional. Sin trazo del plan y sin estado del motor, no hay nada que la app pueda inventar
(no calcula rutas por calles). El trabajo pendiente es 100% backend/infra.

## RESOLUCIÓN (2026-11-17): la causa raíz ERA de la app

El backend (logistics-e8) diagnosticó en staging (solo lectura) y mis 3 hipótesis apuntaban a la capa
equivocada. Hallazgo: el motor de desvío/reroute está OK y con todo cumplido (deviation.enabled, plan
PUBLISHED con 1028 coords, 57 envíos a bordo), pero **`telemetry_pings` no recibía un ping desde el 10-nov**.
El nginx muestra a la app mandando GPS a `POST /app/tracking/shipments/{id}/position` (202), **no** a
`POST /app/telemetry/pings`. El endpoint por-envío solo actualiza la miga de pan (contexto TRACKING): no crea
trip, no setea `off_route_since`, no emite `VehicleDeviationStarted`, no dispara el reroute. El motor de
off-route vive EXCLUSIVAMENTE en la ingesta de telemetría (`/app/telemetry/pings`).

**FIX aplicado (lado app, ya en el working tree):** `truck_tracking_service._flush` ahora encola kind
`recordVehiclePings` → `POST /app/telemetry/pings` (lote), con `vehicle_id` (requerido) + `route_id`,
`speed_kph` (=speed_mps×3.6), `heading` entero, `fix_id` = `"{vehicle_id}:{recorded_at ISO}"` (idempotencia;
el endpoint no lleva Idempotency-Key). `vehicle_id`/`route_id` se cablean desde la ruta del chofer.
`driver_id` va nulo (opcional; `Session.userId` es int, no uuid). Respaldo al endpoint por-envío solo si
faltara `vehicle_id`. Purga de GPS stale + tests (dispatcher + tracking service) actualizados.

**Red de seguridad server-side (backend, sin desplegar):** `ShipmentPositionBridge` — el controller del
endpoint por-envío, además de la miga de pan, mete la lectura por el mismo camino que `/telemetry/pings` (si
el vehículo está A BORDO), con el MISMO `fix_id` → si un fix llegara por ambos, colapsan por idempotencia.
Interruptor `TELEMETRY_BRIDGE_SHIPMENT_POSITION` (default TRUE). Defensa en profundidad, no reemplaza el fix
de la app.

**Pendiente:** el dueño instala el build nuevo y maneja con camión en ruta + carga a bordo para generar pings
frescos; ahí el off_route/reroute debería salir solo. (El scheduler `RefreshVehicleEtas` NO es necesario para
esto: el reroute se dispara por EVENTO `VehicleDeviationStarted`, no por cron.)

Ver [[gps-ping-endpoint]] (corregida), [[driver-tracking-count-single-source]],
[[checklist-por-ruta-y-hora-entrega]].
