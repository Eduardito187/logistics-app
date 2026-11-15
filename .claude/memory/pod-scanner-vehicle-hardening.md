---
name: pod-scanner-vehicle-hardening
description: "nov 2026 — fixes de entrega/escáner/asignación: scanner no-negro, sin \"QR del cliente\", bulto validado vs envío, selector de vehículos reales; binding al backend pendiente"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-13T14:55:03.329Z
---

Batch de endurecimiento del reparto (nov 2026, probado en staging con el teléfono):

- **Login mostraba el error anterior** en el siguiente intento (AsyncLoading conserva el error vía copyWithPrevious): el listener ahora ignora el error mientras `isLoading`. Test de regresión en `login_screen_test`.
- **Teclado quedaba abierto al navegar**: `KeyboardDismissObserver` en el router suelta el foco en cada push/pop/replace. Los diálogos con `autofocus` lo reabren después del push.
- **Escáner en negro/colgado** (`scanner_screen.dart`, mobile_scanner 7.2.0): no arrancaba explícito ni manejaba errores → se agregó `_startCamera()` en initState + `errorBuilder`/overlay con "Reintentar" (permiso/cámara en uso). Antes: pantalla negra sin feedback.
- **"QR del cliente" NO existe** en reparto a domicilio: se quitó el botón de `pod_screen.dart`; la confirmación es **solo firma** (FIRMA_DIGITAL). Pendiente confirmar si tienda/transportista (recojo) sí tienen código de recojo (ver doc).
- **Cerrar un pedido que no corresponde**: `scanVerifiedUnit` devolvía el bulto de CUALQUIER etiqueta. El POD ahora valida que el bulto pertenezca al `shipment_id` de la parada (`driverShipmentUnitsProvider`); si es de otro pedido, rechaza con aviso. Sin red o **lista VACÍA** → no bloquea (el backend aún no puebla bultos por parada; nunca rechazar por lista vacía).
- **POD multi-bulto (nov 2026)**: el POD cerraba con UN SOLO bulto (`_unitId`). Ahora acumula TODOS los bultos del pedido (`_unitIds`), muestra "Escaneados X de N" (N = `driverShipmentUnitsProvider`), no deja repetir, y al registrar manda **un POD por bulto** (outcome combinado: falló/encolado/enviado). Si no se sabe N (backend sin datos) exige ≥1, no un total. Ver [[label-key-rotation-footgun]] (modelo abierto k:0).
- **Asignar vehículo = selector de flota real** (`availableVehiclesProvider` → `/app/fleet/vehicles`), no texto libre. `AssignLaneDialog` ahora es un picker buscable. El preparador SÍ puede listar `/app/fleet/vehicles`.

**"No se pudo registrar" el POD = "no hay entrega abierta" (12-nov, CAUSA RAÍZ real, diagnóstico por USB).** Tras arreglar `photo_path` y el null-strip, el POD SEGUÍA fallando. Diagnóstico definitivo leyendo la **cola offline del teléfono por USB** (`adb ... run-as bo.com.dismac.logistics_app cat app_flutter/logistics_app.sqlite` → tabla `outbox_actions`, columna `last_error`): **"no hay entrega abierta para el envío <uuid>"**. Es error de DOMINIO del backend (la validación pasa). El POD exige `deliveries->findByShipmentId(shipment) != null`; **lo ÚNICO que abría la entrega** (`Delivery::start`) era `RecordPreparationScanHandler`. Al **sacar "Verificar productos con escaneo"** del preparador (pedido del dueño, el escáner no leía) y reemplazarlo por "asignar vehículo = preparado", el app dejó de abrir la entrega (hoy `_assignLane` solo llama `POST /app/orders/{order}/vehicle`, que no la abría). Síntoma colateral: 216 PLANNED + 168 RECEIVED, 0 en ejecución; ninguna entrega abierta. El app NO puede abrirla solo (`EmittedLabel` no tiene `shipment_id`/`unit_id`). **Fix = BACKEND, sin cambio de app** (logistics-5b): `AssignOrderVehicleController` ahora despacha `OpenDelivery(shipmentId, vehicleId)` idempotente por cada envío de la orden → abre la entrega al asignar el vehículo. El dueño redepliega + re-asigna el vehículo → entrega abierta → carga+POD funcionan. **Bandera:** reasignar a OTRO vehículo conserva el vehículo original en la entrega (POD funciona igual, usa el envío); mover la entrega al vehículo nuevo es cambio extra de dominio (pendiente de confirmar con el dueño). **Técnica de diagnóstico clave:** cuando "No se pudo registrar" y no se ve el 422 (Laravel no loguea validación), leer `outbox_actions.last_error` de la DB del teléfono por USB; es la respuesta exacta del backend. Ver [[staging-server-access]].

**Lo que depende del backend** (doc `docs/backend-requests/2026-11-11-asignacion-vehiculo-y-pod-validaciones.md`):
1. La asignación de vehículo es **estado LOCAL**: falta endpoint que **ate el envío al vehículo/ruta** (hoy el tracking no se liga de verdad). Ver [[labeling-order-multishipping]].
2. `POST /app/deliveries/proof-of-delivery` da **500** al cerrar directo por API (falta precondición/secuencia de scans; debería ser 422 con motivo).
3. `/app/vehicles/{id}/route` (SCZ-2611xx) y `/app/vehicles/{id}/deliveries` (SCZ-2610xx) **no coinciden** → el shipment de la parada no se resuelve por /deliveries.

**POD chofer: "No se pudo registrar" tras el deploy de opción A (12-nov, CRÍTICO).** El POD del chofer (`pod_screen.dart`) seguía mandando `photoPath: photo != null ? 'pendiente' : null`. Como la foto es obligatoria, SIEMPRE mandaba `photo_path: 'pendiente'`. Antes del deploy el backend lo aceptaba; al desplegar #3/opción A, el `ProofOfDeliveryRequest::verifyPhotoEvidence()` revisa que **cada `photo_path` enviado EXISTA en disco de evidencia** (`EvidenceStorage::exists`), y `'pendiente'` no existe → **422 `photo_path`** ("The photo was not uploaded...") → la cola lo marca `failed` → "No se pudo registrar". Fix: mandar `photoPath: null` (la foto va por `enqueueDeliveryPhotoProvider` y el backend la liga al envío; queda `pod_photo_pending`). Verificado contra el controlador DESPLEGADO (`packages/logistics/execution/.../Request/ProofOfDeliveryRequest.php`): con `photo_path` null/ausente → `photoReferences()` = [] → sin error. **El store POD ya estaba bien; solo el chofer mandaba 'pendiente'.** Regla: NUNCA mandar una ruta de foto inventada; null u omitir.

**SEGUNDA causa del 422 (la que faltaba) — campos opcionales en `null` (SISTÉMICO, todos los escaneos).** Tras el fix del `photo_path` SEGUÍA el 422. Causa: el `ScanRequest::baseRules()` desplegado valida `device_id => ['sometimes','string']` y `user_id => ['sometimes','string']` **SIN `nullable`**, y el cliente generado (json_serializable, `.g.dart`) incluye SIEMPRE los opcionales en el cuerpo aunque valgan `null`. En Laravel `sometimes` NO saltea una clave presente-con-`null`, y `string` sobre `null` → **422**. Afecta a TODOS los escaneos (load/unload/preparación/recepción/POD usan el mismo `baseRules`). Fix app-side SISTÉMICO: `lib/core/network/null_body_strip_interceptor.dart` (`NullBodyStripInterceptor`, cableado en `dio_client.dart`) quita las claves de PRIMER nivel con valor `null` del cuerpo → el campo queda AUSENTE → `sometimes` lo saltea. Conserva 0/false/''; no toca mapas anidados (login.device) ni FormData (fotos). `idempotency_key` viaja igual por el header. **Diagnóstico:** Laravel NO loguea los 422; se confirma leyendo la regla en el contenedor (`docker exec ... cat .../Request/*.php`) y comparando con el `.g.dart`. El fix de fondo ideal es del BACKEND (`sometimes|nullable|string`), pero el interceptor lo resuelve sin depender de un deploy. 2862 tests verdes.

**POD "No se pudo registrar" — ÚLTIMO eslabón: máquina de estados de la entrega (12-nov, leído de logs staging).** Tras arreglar photo_path, device/user (del token, backend) y fechas, el POD SEGUÍA fallando con error de DOMINIO: **"transición inválida a Delivered desde PENDING"** (`Delivery::markDelivered` exigía `[Loaded, InTransit]`). Causa: la máquina de estados era Pending→(prep scan)Prepared→(load scan)Loaded→(POD)Delivered, pero el flujo simplificado del dueño SACÓ del app los escaneos de preparación y carga; `OpenDelivery` abría en PENDING y nada la avanzaba → clavada. **Semántica CORRECTA del dueño (que definió y el backend implementó):** "Preparada" = **etiqueta EMITIDA** (nivel envío, ANTES, no es estado de la entrega); **"Cargada" = asignada a un camión** → la entrega **NACE en `Loaded`** al asignar (`Delivery::open` → Loaded, emite solo `DeliveryOpened`, NO ShipmentPrepared/Loaded para no disparar notificaciones); **reasignar = sigue Cargada** (`Loaded→Loaded`, evento `DeliveryVehicleReassigned`, no retrocede); **Entregada = directo desde Cargada**. NO es lineal estricto. Backend (logistics-42) también relajó el guard: POD/Failed aceptan además **Pending/Prepared** como RED para desatascar las ~384 ya trabadas SIN backfill (el chofer hace POD directo). El único "transición inválida" que queda válido es sobre una entrega YA cerrada. **Sin cambio de app.** El dueño redeploya el backend y el POD entra. Comando one-shot OPCIONAL (cosmético): avanzar las PENDING sin POD → Loaded para que no muestren "pendiente".

**Guardia anti-DUPLICADOS por SKU en el POD (12-nov).** Por la re-emisión de etiquetas quedaron DUPLICADAS (misma orden+SKU, distinto `unit_id`); el dedup por `unit_id` no las cachaba y escanear 2 de la misma contaba 2 entregas. Fixes en `pod_screen.dart`: (1) `_expectedCount = min(unit_ids.length, suma de cantidades de ítems)` cuando se conocen ambos → el total nunca supera la cantidad real del pedido (una unidad duplicada no suma); (2) guardia por SKU en `_scanUnit`: si ya se escanearon todas las unidades del pedido para ese SKU (de `stop.items`), rechaza "esa etiqueta está duplicada". Solo aplica si se conoce el SKU del QR y el pedido lista ese SKU (Code128/SKU ajeno → no bloquea, offline-first). Tests nuevos en `pod_screen_test`. Ver [[no-label-mutations-rule]], [[label-key-rotation-footgun]].

**Mostrar el MOTIVO real del rechazo en el POD (13-nov).** El dueño pedía ver POR
QUÉ falla la entrega en vez de "No se pudo registrar. Intentá de nuevo." (genérico
que obligaba a leer la cola por USB). Fix app: `OfflineQueue.submit` ahora acepta
`onReject(ApiException)` (opcional, no-rompedor) que corre SOLO en un 4xx permanente
(`SubmitOutcome.failed`), NO en transitorios (sin red/401/429/5xx → queued). El POD
(`pod_screen.dart`) captura `error.message` (= el `detail` del backend, gracias al
contrato unificado [[unified-error-contract]]) y lo pasa a `showSubmitOutcome(...,
failureDetail:)` → el chofer ve el motivo real en el SnackBar. `submitOutcomeMessage`
toma `failureDetail` opcional; vacío → genérico. Tests en `submit_feedback_test` y
`offline_queue_test`. Diagnóstico ya NO depende de sacar la DB del teléfono.

**Error real vigente (13-nov, leído de `outbox_actions.last_error`):** el POD de
Valeria Rojas (envío 01a1c719-8163-…) da **"no hay entrega abierta para el envío
…"** = MISMA clase que el eslabón de dominio: la entrega no está abierta
(OpenDelivery no se disparó al asignar, o el backend no está deployado). El app NO
la abre solo → es del BACKEND (logistics-42, ya avisado con el error exacto). Otro
POD viejo (01a1c719-8152-…) daba "transición inválida a Delivered desde DELIVERED"
= ya estaba entregado y el reintento con otra idempotency_key choca (se pidió al
backend que ese caso devuelva 200 idempotente). La foto NO es la causa: el POD manda
`photo_url: null` y falla ANTES de evaluar la foto. El dueño quiere además la foto
INLINE con el POD (multipart/base64) por robustez — pendiente de que el backend dé
el formato; NO arregla el "no hay entrega abierta".

**EL NUDO = DEPLOY (13-nov, confirmado con el backend logistics-42).** Todos los
arreglos del POD (auto-abrir entrega al asignar vehículo, AUTO-ABRIR en el propio POD
tomando el camión de la ruta del chofer si no hay entrega, guard relajado, idempotente
ya-Delivered, casing cosmético) viven en el WORKING TREE del backend del dueño, **sin
commitear/deployar**. Mientras no se deploye el backend de STAGING
(137.131.245.152:8110), el "no hay entrega abierta" sigue. El dueño debe: (1) commit +
deploy, y (2) correr el comando artisan NUEVO para reconciliar en lote (lo corre EL
DUEÑO o el agente por `ssh oci` + docker exec, NO el app):
`php artisan logistics:execution:open-missing-deliveries [--force] [--shipment=<uuid>]`
(dry-run sin --force; abre en Loaded las entregas faltantes de envíos en ruta; NO
re-emite etiquetas). El "casing Delivered vs DELIVERED" era SÓLO cosmético (el guard
compara identidad de enum, no strings); ya normalizaron el mensaje.

**Foto del POD — DOS flujos listos en backend (pendiente deploy), inline DIFERIDO.** El
backend soporta: (A) INLINE = POST /app/deliveries/proof-of-delivery como
**multipart/form-data** con campo `photo` (archivo) → liga la foto en la misma
transacción; (B) APARTE = POST /app/deliveries/photos → `photo_path` → POD con ese path
(flujo B = el confiable para offline/cola, el que usa el app HOY vía
`enqueueDeliveryPhotoProvider`). Límites inline: sólo imagen, 10 MB máx. **El app YA
optimiza** antes de subir (`kEvidencePhotoMaxWidth=1600`, `kEvidencePhotoQuality=70` →
~0.5-1.5 MB, EXIF respetado por image_picker), así que la foto ya sube bien hoy, sólo
que en 2º paso. **Decisión: NO cablear el inline durante el incendio del deploy** (tocar
el POD, el flujo más crítico, mete bugs; además la foto NO era la causa, el POD falla
ANTES por la entrega no abierta). Plan: destrabar entregas (deploy) → confirmar → recién
ahí cablear inline como best-effort additivo (online 1 request; offline/falla → flujo B
de cola). Pendiente del dueño: "ya deployé" + OK para el inline.

Relacionado: [[unified-error-contract]], [[apk-size-split-abi]], [[staging-server-access]],
[[windows-native-toolchain]], [[run-environments-config]] (footgun del `10.0.2.2` en debug físico).
