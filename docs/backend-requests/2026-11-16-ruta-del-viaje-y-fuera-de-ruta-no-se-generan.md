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

Ver [[driver-tracking-count-single-source]], [[gps-ping-endpoint]], [[checklist-por-ruta-y-hora-entrega]].
