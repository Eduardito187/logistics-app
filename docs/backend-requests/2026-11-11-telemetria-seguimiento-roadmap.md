# Telemetría y seguimiento — ítems del roadmap que viven en el backend/web

**Fecha:** 2026-11-11 · **Pedido por:** app (`logistics-app-f4`) · **Backend:** `logistics-1a`
**Estado:** pedido (roadmap, no bloqueante). Son features server/web; la app las CONSUME cuando existan.

Del roadmap de seguimiento (`docs/roadmap-seguimiento-flota.md`), estos puntos NO son app-side: la app
ya manda posiciones por la cola de telemetría, pero el histórico, el análisis y la vista de supervisión
viven en el servidor. Cuando el backend los exponga, la app los consume.

## 1. Breadcrumbs server-side + replay (roadmap #23)
Guardar el histórico de posiciones del camión (lat/lng/ts/velocidad) por envío/ruta y exponer:
- `GET /app/tracking/shipments/{id}/breadcrumbs?from&to` → lista de puntos (para replay del recorrido).
- Retención/resolución a definir (p. ej. 1 punto cada 10–30 s, 30–90 días).
Beneficio: auditoría ("por dónde fue"), soporte de reclamos, analítica de rutas.

## 2. Alertas de telemetría server-side (roadmap #19, #20, #25)
Detectar y notificar (push/web) eventos de la telemetría que ya recibís:
- **Velocidad excesiva** (> umbral por zona/horario).
- **Ralentí/detención prolongada** fuera de parada (> N min detenido sin entregar).
- **Desvío de ruta** (> X m del trazo por > Y s). *(La app ya muestra "Fuera de ruta" localmente, pero
  la alerta al supervisor es server-side.)*
- Salida de horario / fuera de zona.
Exponer un feed de alertas para el panel del supervisor y, si corresponde, push al chofer.

## 3. ETA dinámico con tráfico (roadmap #21)
Hoy la app estima el ETA con `route_geometry` (distancia/tiempo del plan) o línea recta. Si el backend
puede devolver un ETA con tráfico (motor de ruteo), exponerlo por parada y la app lo muestra en vez del
estimado propio.

## 4. Vista en vivo multi-camión del supervisor (roadmap #24)
Panel web (Filament) con la posición en vivo de todos los camiones a la vez + su estado de ruta. Es
front web del backend, no de esta app; se menciona para cerrar el roadmap.

## Lo que YA resolvió la app (para contexto)
- Posiciones a la cola de telemetría (offline-first) y mapa en vivo del chofer con auto-enfoque.
- "Fuera de ruta" y "Llegaste a destino" (geocerca) mostrados localmente en la entrega en curso.
- Odómetro salida/llegada, inspección diaria + historial, km recorridos.

## Pendiente app (próximo ciclo, NO backend — requiere prueba en dispositivo real)
Muestreo GPS adaptativo por velocidad, modo ahorro de batería, suavizado/snap-to-road del marcador e
interpolación entre fixes. Tocan el servicio de GPS en segundo plano (estabilidad sensible), así que se
hacen con el equipo a mano, no a ciegas.
