# Armar un viaje: al guardar devuelve OTRO plan (pedidos ajenos), carriles por parada y hora distinta

**Fecha:** 2026-11-17 · **Pide:** app (logistics-app) · **Para:** backend (logistics-e8)
**Prioridad:** 🔴 Alta · bug de terreno (el dueño lo vio en el teléfono)

## Síntoma (fotos del dueño)

El dueño armó un viaje en "Armar un viaje" con **4 pedidos que eligió y ordenó** a mano:
1. `01a1e992-5409-7621-91fc-17faf623d4a3` — TEST SCZ 3 LasPalmas
2. `01a1e992-53ae-7e8b-bda2-61572c057c7e` — TEST SCZ 1 Equipetrol
3. `01a1e992-5426-7cc9-9d74-a37390040428` — TEST SCZ 4 Centro
4. `01a1e992-53ed-7f28-a6f0-2704a19a3c2d` — TEST SCZ 2 Plan3000

Salida seleccionada **09:15**. Tocó **"Guardar viaje · 4 paradas"**. El detalle que se abrió mostró un
plan **completamente distinto**: pedidos `SCZ-261115-01/02/05/04` (Marcelo Saucedo, Valeria Rojas, Carolina
Justiniano…), con **llegadas 08:15 / 08:46 / 09:18…** y **carriles A/B por parada** — ninguno de los 4 que
eligió. O sea: su viaje NO se guardó como lo armó y terminó viendo un plan ajeno (parece el del
`TodayScenarioSeeder` / demo del día).

## Qué manda la app (verificado en el código)

`createTrip` hace `POST /app/plans` con exactamente lo elegido:

```json
{
  "plan_date": "2026-11-17",
  "vehicle_id": "<el camión elegido>",
  "depart_at": "<09:15 local → UTC, toIso8601String>",
  "stops": [
    {"shipment_id": "01a1e992-5409-..."},
    {"shipment_id": "01a1e992-53ae-..."},
    {"shipment_id": "01a1e992-5426-..."},
    {"shipment_id": "01a1e992-53ed-..."}
  ]
}
```

Los `shipment_id` son los que devuelve `GET /app/plans/trip-candidates` (no inventados). La app navega al
plan que devuelve la respuesta (`PlanEnvelope.data.id`). El contrato que la app espera: si el camión YA tiene
plan ese día → **409** con `plan_id` (la app lo trata como `TripAlreadyPlanned`).

## Diagnóstico

El plan mostrado es el **sembrado del día** (SCZ-261115, llegadas ~08:00, carriles A/B). Dos causas posibles,
ambas del backend:

1. **El camión elegido YA tenía el plan sembrado ese día** y `POST /app/plans`, en vez de **409**, devolvió
   **200 con ese plan existente** (ignorando los `stops` y el `depart_at` nuevos). → la app lo tomó como
   "guardado" y abrió el plan ajeno. **Si debe devolver 409, confirmar que lo hace**; si por diseño
   "mergea", NO debe descartar los stops nuevos ni el depart_at.
2. O el camión no estaba planificado y aun así `createTrip` **no respetó** los `stops`/`depart_at` enviados y
   devolvió otro plan.

En cualquier caso: **el plan devuelto no contenía los `shipment_id` enviados.** Eso es lo que la app ahora
detecta (ver abajo).

## Lo que ya hizo la app (mitigación, desplegable)

- **Guarda de integridad:** tras `createTrip`, la app verifica que el plan devuelto **contenga los
  `shipment_id` que armó**. Si no (plan ajeno / existente), **NO** dice "guardado" ni navega en silencio:
  avisa *"El viaje no se guardó con los pedidos que armaste: ese camión ya tiene un viaje ese día…"* y
  **conserva el armado** (no se pierde el trabajo), con un botón "Ver viaje" para abrir el existente.
- **409 no destructivo:** antes, ante `TripAlreadyPlanned`, la app reemplazaba la pantalla y abría el plan
  ajeno. Ahora avisa *"Ese camión ya tiene un viaje ese día. Elegí otro camión o abrí el viaje existente"* y
  conserva el viaje armado; "Ver viaje" lo abre si el usuario quiere.

## Lo que necesita del backend

1. **`POST /app/plans` debe crear el viaje con los `stops` y `depart_at` enviados, o devolver 409** si el
   camión ya tiene plan ese día — nunca 200 con un plan ajeno. Confirmar cuál de los dos caminos ocurre hoy
   con el camión que eligió el dueño.
2. **Carriles de carga (`PlannedStop.lane`):** el dueño pide que las paradas de un viaje carguen en el
   **MISMO carril**, no un carril distinto por parada ("no tiene sentido mover el carril por cada producto").
   Hoy el plan asigna A/B/… por parada. ¿Es intencional? Si no, que un viaje use un solo carril (o explicar
   la regla). La app solo muestra `stop.lane`.
3. **Hora de salida (`depart_at`):** el dueño eligió 09:15 y el plan mostró ~08:00/«11:30». La app envía la
   hora local convertida a UTC (`DateTime(local).toUtc().toIso8601String()`). Confirmar que el backend la
   interpreta/guarda/devuelve respetando la zona (Santa Cruz UTC−4) y no la corre.
4. **Ideal (evita el problema de raíz):** que `GET /app/plans/trip-candidates` (o el picker de camiones)
   indique qué **camiones ya tienen plan** ese día, para no dejar elegir uno tomado y perder el armado.

Ver [[planner-role-and-planning]], [[plans-viajes-browser-filters]], [[owner-decisions-are-final]].
