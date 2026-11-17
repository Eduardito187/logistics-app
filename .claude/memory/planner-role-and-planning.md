---
name: planner-role-and-planning
description: "nov 2026 — rol Planificador (backendKey planificador) y planificación desde la app; supervisor solo mira; armado de viajes con sugerencias espera al backend; preferencias de UI del dueño (selects, sin UUID, sin \"SKU\", hojas al alto del contenido)"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-15T05:19:25.449Z
---

**Decisión del dueño (2026-11-15):** le gustó el "personal planificador" y quiere planificar desde la app.

**Quién planifica:** antes NO existía el rol; en el backend `planning.write` lo tienen supervisor y admin, y
hay un planificador automático nocturno (21:00; la publicación automática viene apagada). En la app:
`UserRole.planner` (`planificador`) y `canPlan` = planificador + admin. El **supervisor solo mira** (se
mantiene la decisión anterior y su test `supervisor_read_only_test`).

**Hecho en la app:** pantalla de planes (`/supervisor/plans`, tarea `plan-day` "Planificación"):
"Planificar el día" (corrida automática asíncrona, se consulta cada 5 s), "Publicar los N planes"; en el
detalle de un plan SIN publicar: Subir/Bajar paradas + "Guardar orden", "Agregar pedido" por código y
"Publicar plan". Publicado = solo lectura (el backend da 409). El planificador también ve Envíos,
Reprogramar, Calendario, Flota y Tablero. Gate por `canPlanProvider` (los tests lo overridean).

**Backend entregado y consumido (2026-11-15, working tree sin deploy):** rol `planificador` (acotado por
ciudad; cuenta planificador@dismac.test aún no existe en dev), textos del plan sin UUID
(`stopTitle`/`stopWho`/`timeWindowText` en `supervisor_labels.dart`), `Shipment.delivery_evidence`,
`?city=` por código de departamento, y el **asistente de viajes** `TripBuilderScreen`
(`/supervisor/trips/new`, tarea `plan-trip`): camión → `GET /app/plans/candidates` (cercanía a la base o al
último elegido, `fits`, `suggested`) → `POST /app/plans/suggest-sequence` con 2+ paradas (orden, km, avisos
`window_missed`…) → `POST /app/plans` (borrador, respeta el orden). 409 con `plan_id` = el camión ya tiene
plan ese día → `TripAlreadyPlanned` y se abre ese plan. Un plan por camión y día. Editor: "Quitar" parada
(`DELETE .../stops/{id}`). Esas llamadas van por Dio directo (fechas `Y-m-d`, `selected` separado por comas).
El dueño quiere que "el backend piense": la app NO calcula cercanías ni órdenes.

**Ronda de observaciones del admin (2026-11-15):** tienda asignada solo para rol tienda y camión solo para
chofer; documentos del personal con tipo en select + número + anverso/reverso (dos subidas con `note`);
la evidencia de entregas (firmas) NO se muestra en la ficha de una persona (dato del cliente); avisos por rol
daban 422 por `user_ids: []` (ahora Dio directo sin la clave); mantenimiento ofrece "Pasarlos a otro camión"
solo si el camión tiene pedidos (`pendingOrdersOf`). Avisos de la empresa DENTRO de Notificaciones
(`InboxSection`), refresco solo: push en primer plano (`pushArrivedProvider`), al volver a la app y cada 20 s.
Los sockets ya están (ver [[realtime-sockets-contract]]); el refresco por tiempo es solo respaldo.

**Preferencias de UI que fijó el dueño:** filtros como SELECT (ciudad, estado, rol), nunca input de texto ni
chips para eso; ningún UUID a la vista; el SKU va solo, sin la palabra "SKU"; foto del producto en los
detalles; las hojas (modales) miden lo que su contenido, sin aire abajo; el rol se llama "Preparador" (sin
"andén"); en un envío entregado, etiquetas de cómo se entregó (firma digital, foto de entrega, foto de
documento). Ver [[owner-decisions-are-final]], [[admin-role-in-app]].

**Agregado el 2026-11-15 (tarde):** detalle del plan = UNA línea de tiempo de tarjetas (`StopTile` con
`eta`, `isFirst/isLast`, `footer`); la hora de llegada sale de `planStopEtasProvider(planId)` y, si no hay, de
`PlannedStop.etaAt`. Se borraron `EtaSection`/`EtaRow` (ya no hay "ETA por parada"). "Publicar plan" /
"Guardar orden" van FIJOS al pie: el editor publica sus acciones en `planEditorActionsProvider(planId)` y la
pantalla las dibuja en `bottomNavigationBar` (solo si `canPlan` y el plan no está publicado). "Guardar viaje"
del asistente también va fijo al pie ("Guardar viaje · N paradas"). **Eliminar plan**: botón en el editor →
`DELETE /app/plans/{id}` por Dio directo (204; 409 si está publicado), cierra el detalle; si lo borran desde
otro teléfono (`plans.updated` con `deleted: true`) el detalle se cierra solo.
