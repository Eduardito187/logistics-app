# Roadmap — Seguimiento del camión y operación de flota (chofer)

> Análisis exhaustivo + hoja de ruta pedida por el dueño (2026-11-11). Cubre tres frentes:
> **(1) seguimiento/mapa del chofer**, **(2) odómetro salida/llegada**, **(3) inspección diaria
> del camión**. Lo marcado **[HECHO]** ya está implementado y testeado en este ciclo.

---

## 0. Qué se implementó ahora (este ciclo)

- **[HECHO] Auto-enfoque inteligente del mapa (entrega en curso).** Cuando NI el usuario mueve el mapa
  NI el camión se mueve por **6 s**, el mapa se acerca suave a la ubicación del camión. Validación
  estricta para no arruinar la UX (no mueve el mapa mientras hay gesto ni mientras el camión anda).
  Archivos: `features/driver/presentation/widgets/active_delivery/delivery_map.dart`
  (`_trackStillness`, `_maybeAutoFocus`, función pura `shouldAutoFocus`) y `widgets/map_motion.dart`
  (`isAnimating`). Tests: `test/features/driver/widgets/auto_focus_test.dart`.
- **[HECHO] Odómetro solo salida/llegada.** La lectura de SALIDA va en el checklist pre-salida
  (`source: departure`); la de LLEGADA en un flujo "Finalizar ruta" al cerrar la ruta. Se quitó el
  odómetro como tarea suelta del inicio.
- **[HECHO] Inspección diaria del camión (diésel).** El checklist pre-salida pasó a ítems diésel
  (motor, aceite, agua/refrigerante, frenos, fugas, llantas, luces, combustible, extintor,
  documentos). Historial por camión + recordatorio diario (reusan `pre-trip-checklists`). Bloqueo por
  ítem crítico (frenos/motor → "NO apto para salir").
- **[HECHO] Km recorridos de la ruta** (odómetro llegada − salida) en "Mi día".
- **[HECHO] Geocerca de llegada (#18)**: "Llegaste a destino" cuando faltan ≤ 60 m y en ruta.
- **[HECHO] Aviso "Fuera de ruta" (#19)** ya estaba y se mantiene; y **validación del odómetro**
  (solo avanza) adelantada en la app.
- **[DELEGADO al backend]** breadcrumbs/replay, alertas de telemetría (velocidad/ralentí/desvío), ETA
  con tráfico y vista multi-camión del supervisor → `docs/backend-requests/2026-11-11-telemetria-seguimiento-roadmap.md`.
- **[PRÓXIMO CICLO — requiere dispositivo]** muestreo GPS adaptativo, modo batería, suavizado/snap-to-road
  e interpolación del marcador: tocan el servicio de GPS en 2.º plano; se hacen con el equipo a mano, no
  a ciegas (sin poder correr/medir en dispositivo bajan la estabilidad).

---

## 1. Seguimiento del camión en el mapa — análisis y opciones

### 1.1 Cómo funciona hoy (base)
- Posición del camión: rastreo GPS en vivo (`truckTrackingProvider`) o lectura puntual
  (`deliveryDriverFixProvider`), filtrada por `plausibleDriverFix` (descarta fixes imposibles para un
  reparto urbano → evita "faltan 12000 km").
- Mapa OSM oscuro, trazo por calles del plan, pines de paradas, marcador de camión orientado al rumbo
  (`TruckMarker`), radar de pulso por fix.
- Cámara: modo **seguir** manual (se apaga al arrastrar), botones acercar/alejar/seguir/centrar,
  animación suave (`AnimatedMapMover`). **[NUEVO]** auto-enfoque al quedar todo quieto.

### 1.2 El auto-enfoque (regla implementada)
`shouldAutoFocus` devuelve `true` solo si: no está el modo seguir activo · no se auto-enfocó ya para
esta quietud · no hay otra animación de cámara · el camión lleva ≥6 s sin moverse (umbral 12 m para
tolerar el jitter) · el usuario no tocó el mapa en ≥6 s. Un `Timer.periodic(1 s)` barato lo chequea.
Se reinicia cuando el camión se mueve o el usuario toca el mapa. Respeta "reducir movimiento".

**Parámetros afinables** (si el dueño quiere otra sensación): ventana 6 s, umbral de quietud 12 m,
zoom objetivo 16.5 (nunca aleja).

### 1.3 Opciones para MEJORAR el seguimiento (catálogo)

**A. Cámara y encuadre**
1. Auto-enfoque que además **encuadre camión + próxima parada** (no solo el camión) cuando están cerca.
2. **Zoom adaptativo por velocidad**: más alejado a más velocidad (ver más adelante), más cerca parado.
3. **Rumbo arriba (heading-up)**: rotar el mapa al rumbo del camión (como Waze) — opcional, con brújula.
4. **Inclinación/pitch 3D** leve en navegación (flutter_map no lo hace nativo; evaluar costo/beneficio).
5. **Re-encuadre al cambiar de parada**: al pasar a la siguiente, animar a camión+nueva parada.
6. **"Volver al camión" con badge** cuando el usuario se alejó y el camión salió de pantalla.
7. **Anillo de ETA/tiempo** alrededor del camión o de la parada (cuenta regresiva visual).

**B. Suavidad del movimiento del camión**
8. **Interpolación entre fixes**: animar el marcador del camión entre lecturas (hoy "salta" cada fix).
9. **Suavizado (Kalman/alpha-beta)** de la posición para menos tembleque con GPS pobre.
10. **Snap-to-road**: pegar la posición a la calle del trazo (menos deriva visual en zig-zag).
11. **Rumbo suavizado** ya existe (umbral 4 m); permitir usar el rumbo del sensor si está disponible.

**C. GPS / batería / datos**
12. **Muestreo adaptativo**: más frecuente en movimiento, más lento parado (ahorra batería y datos).
13. **Significant-location / distanceFilter** nativo para no procesar fixes redundantes parado.
14. **Buffer offline de posiciones** y envío por lotes al recuperar señal (ya hay cola offline; extender).
15. **Modo ahorro** cuando la batería está baja (baja la frecuencia, avisa).
16. **Persistir última posición conocida** para abrir el mapa centrado al instante (sin esperar el 1er fix).
17. Afinar el **foreground service** (ya existe, fantasma en 1er plano) para frecuencia/precisión por estado.

**D. Inteligencia de ruta**
18. **Detección de llegada por geocerca** (geofence) a la parada → ofrecer "Entregar" automáticamente.
19. **Alerta de desvío de ruta** (el camión se salió del trazo > X m por > Y s).
20. **Detección de "detenido mucho tiempo"** (posible problema) → aviso suave / reporte.
21. **ETA real por motor de ruteo** (el backend ya manda `route_geometry` con distancia/tiempo; usarlo
    para ETA dinámico con tráfico si el backend lo provee).
22. **Reordenar paradas** sugerido por cercanía (si el negocio lo permite).

**E. Supervisión (lado web/backend)**
23. **Breadcrumbs server-side**: guardar el histórico de posiciones para replay y auditoría.
24. **Vista en vivo del supervisor** (varios camiones a la vez) — ya hay panel web.
25. **Alertas**: velocidad excesiva, ralentí prolongado, fuera de horario, fuera de zona.

**F. Accesibilidad / terreno**
26. Botón físico grande "centrar en mí" (ya está), **alto contraste** del trazo bajo sol (ya hay tema).
27. **Modo una mano**: controles al alcance del pulgar (ya están abajo a la derecha).

---

## 2. Odómetro — salida y llegada  **[HECHO]**

- **Salida**: campo "Odómetro de salida" en el **checklist pre-salida**. Al guardar, se registra con
  `source: departure` (best-effort: si falla no frena la inspección).
- **Llegada**: botón **"Finalizar ruta (odómetro de llegada)"** en "Mi ruta de hoy", visible cuando no
  quedan paradas pendientes → pantalla de odómetro preseteada (nota "Llegada al CD").
- Se quitó el odómetro como **tarea suelta** del inicio (ya no se pide en cualquier momento).
- **Pendiente backend (chico):** valor `arrival` en `RecordOdometerRequestSource` (hoy la llegada usa
  `manual` + nota). Doc: `docs/backend-requests/2026-11-11-odometro-arrival-source.md`.

**Mejoras futuras odómetro:** validar que llegada ≥ salida; mostrar **km recorridos de la ruta**
(llegada − salida) en "Mi día"; precargar el último valor; foto del tablero como evidencia (reusar la
cámara/evidencia ya existente).

---

## 3. Inspección diaria del camión (mantenimiento diésel)  **[HECHO]**

- El **checklist pre-salida ES la inspección diaria**. Ítems diésel: motor (ruidos/funcionamiento),
  aceite, agua/refrigerante, frenos, llantas, luces, fugas, combustible, extintor, documentos.
- **Historial por camión** (pantalla nueva) + **recordatorio diario** si hoy no se hizo (reusa
  `GET /app/fleet/pre-trip-checklists?vehicle_id=…`).
- No requiere backend nuevo.

**Mejoras futuras mantenimiento:** foto de evidencia por ítem crítico; severidad por ítem (obs leve vs
bloqueante); bloquear "salir" si falla un ítem crítico (frenos); recordatorio push a la mañana;
tendencia por camión (qué falla seguido); enlazar con `maintenance_due` (servicios por km/fecha).

---

## 4. Hoja de ruta por fases (prioridad × esfuerzo)

### P0 — Hecho en este ciclo ✅
- Auto-enfoque del mapa en reposo · Odómetro salida/llegada · Inspección diaria + historial + recordatorio.

### P1 — Alto impacto, bajo/medio esfuerzo (siguiente)
1. Interpolación del marcador del camión entre fixes (#8) — se siente "pro" al toque.
2. Persistir y abrir con la última posición conocida (#16).
3. Km recorridos de la ruta (llegada − salida) en "Mi día" + validación llegada ≥ salida.
4. Botón "volver al camión" cuando salió de pantalla (#6).
5. Severidad/bloqueo por ítem crítico en la inspección (frenos) (#sección 3).
6. Valor `arrival` del odómetro (backend) + swap del `source`.

### P2 — Medio impacto / medio esfuerzo
7. Zoom adaptativo por velocidad (#2) + encuadre camión+parada (#1, #5).
8. Geocerca de llegada a la parada → ofrecer "Entregar" (#18).
9. Muestreo GPS adaptativo + modo ahorro de batería (#12, #15).
10. Suavizado de posición (#9) y snap-to-road (#10).
11. Foto del tablero como evidencia del odómetro; foto por ítem crítico de la inspección.
12. Recordatorio **push** de la inspección a primera hora (requiere credenciales FCM pendientes).

### P3 — Mayor esfuerzo / requiere backend o decisión de producto
13. Rumbo-arriba / rotación del mapa (#3).
14. Breadcrumbs server-side + replay + alertas (velocidad/ralentí/desvío) (#19, #20, #23, #25).
15. ETA dinámico con tráfico (si el backend lo provee) (#21).
16. Vista en vivo multi-camión para supervisor (web).
17. Tendencias de mantenimiento por camión (qué falla seguido).

### P4 — Exploratorio
18. 3D/pitch en navegación (#4) · reordenar paradas por cercanía (#22).

---

## 5. Pendientes de backend (resumen)
- **Odómetro `arrival`** en el enum (chico, aditivo) — `2026-11-11-odometro-arrival-source.md`.
- (Futuro P3) breadcrumbs/replay, alertas de telemetría, ETA con tráfico.
- Nada para la inspección diaria (ya existe `pre-trip-checklists` POST+GET).

> **Nota:** este roadmap es vivo. Los números no son un compromiso de alcance sino un menú priorizado:
> el dueño elige qué entra en el siguiente ciclo.
