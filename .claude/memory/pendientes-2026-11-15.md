---
name: pendientes-2026-11-15
description: "Cierre del 15-nov-2026: qué quedó hecho sin commit ni prueba en teléfono, qué espera al backend (pausado por el dueño) y qué decisiones debe tomar el dueño"
metadata:
  type: project
---

**Estado de la app al cierre del 2026-11-15:** `flutter analyze` 0 issues, `flutter test` 3033/3033. TODO el
trabajo del día está SIN commit (el dueño no lo pidió) y SIN probar en el teléfono.

**Hecho ese día (app):** tiempo real por sockets (ver [[realtime-sockets-contract]]); rol planificador,
armado de viajes, eliminar plan, línea de tiempo y botones fijos (ver [[planner-role-and-planning]]); cambio
de camión que reemplaza + ícono de flota (ver [[crew-duplicate-and-route-extra-stops]]).

**Espera al backend** (la sesión del backend quedó PAUSADA por el dueño; nada desplegado en staging):
- arreglo atómico de tripulaciones (`POST /app/fleet/crews` reemplaza; 409 + `replace: true`) y saneo del
  duplicado existente;
- armado de la ruta del chofer solo con las paradas del plan (hoy trae 31 en vez de 7) y saneo de rutas;
- emitir `route.updated`, y desplegar `channels` / `fleet.*` / `planning.*` / `notifications.updated`;
- los fixes de SonarCloud del PR 88 del backend están en el árbol del dueño sin commitear.
Cuando el backend confirme contratos finales, revisar nombres de eventos contra lo que consume la app.

**Pendiente del lado app / del dueño:**
- probar en el teléfono: arreglo del logo en el login y de la lista vacía del preparador (hipótesis de
  isolates en release, ver [[release-isolate-hang-blank-screens]]), y todo lo del día;
- sin usar todavía: `ready_for_pickup`/`at_store_at` del tracking, `route_id`/`route_status` de my-crew,
  `Delivery.with_shortage`.

**Ronda de UI del admin (2026-11-15, noche) — hecho, suite 3041/3041, sin commit:**
- Datos personales y "Agregar documento" son PANTALLAS COMPLETAS (`widgets/personal_data_form.dart`,
  `widgets/staff_document_form.dart`), no diálogos; el documento muestra recuadros "Anverso"/"Reverso" que se
  tocan para sacar la foto y dan vista previa; "Guardar" fijo al pie. Al dueño le parecieron horribles los
  `AlertDialog` con campos apilados y los botones "Sacar foto del anverso/reverso".
- Filtros SIEMPRE como select (también estado de camiones, rol y destinatario del aviso): nada de chips.
- Avisos al personal: vista previa con la misma `InboxItemCard` que ve el personal, barra de leídos.
- Notificaciones: `InboxAlerts` + `LocalAlerts` (`core/push/local_alerts.dart`) muestran en la barra del
  teléfono el aviso que llega por socket (sin Firebase) y piden el permiso al entrar; no duplica si el push
  FCM está registrado. Avisos con caché corta; "Sin notificaciones" solo si de verdad no hay nada.
- Calendario de entregas: grilla mensual + tarjeta del día; "Agregar cupos por hora" usa
  `POST /app/delivery-calendar/open` (un día, una ventana, opciones de `/options`). Bloquear HORAS espera al
  backend: `GET /app/delivery-calendar/day`, `POST|DELETE /app/delivery-calendar/blocked-slots` (endpoint
  aparte a propósito: mandar `time_slot` a `/blocked` bloquearía el día entero). Con 404 la sección no se ve.
- Envíos: "Cerrar traspaso con faltantes" (solo admin/supervisor, traspaso en curso) →
  `POST /app/deliveries/{id}/close-transfer` con motivo.
- El dueño descartó para esta sesión: commit, build del APK y e2e del recojo en tienda ("no te corresponde").

**Al cierre de la noche del 2026-11-15:** el backend lanzó un agente dedicado al bloqueo de horas del
calendario (contrato de la app tal cual) y va a sumar `capacity_total` / `capacity_used` por día; la app
todavía NO pinta qué tan lleno está cada día (ofrecido al dueño, sin respuesta). Skills nuevas en el repo:
`realtime-feature` (cómo sumar tiempo real a una pantalla) y `backend-coordination` (cómo derivar al backend
e implementar contra un contrato sin desplegar); `flutter-feature` suma las preferencias de diseño del dueño.
