# Escaneo Code128 (Zebra): endpoint de resolución por `label_id`

**Fecha:** 2026-11-10 · **Pedido por:** app (sesión `logistics-app-f4`) · **Backend:** sesión `logistics-1a`
**Estado:** **ENTREGADO (contrato) + app CABLEADA** (código, sin compilar). Backend `logistics-1a`
confirmó el endpoint y agregó `revoked` + `order_number`. Falta confirmar contra dev (el dueño corre
flutter) y el commit/push de la rama del backend.

## Contrato recibido (2026-11-10)

- **Ruta:** `GET /app/labels/{labelId}/resolve` (name `labels.resolve`, `LabelController::resolveUnit`).
  El `labelId` va en el PATH. Puerta app = token usuario+dispositivo (mismo auth que emit/dispatch-lines),
  sin rate-limit propio.
- **Entrada:** el `label_id` (del QR se extrae `payload.id`; del Code128 es el valor crudo).
- **Respuesta SIEMPRE 200** (`LabelUnitView.toArray()`), hay que mirar `resolved` (no hay 404):
  ```json
  { "label_id":"...", "resolved":true, "revoked":false, "order_number":"100000452",
    "unit_id":"...", "shipment_id":"...", "sku":"...", "product_name":"...", "line_number":1,
    "unit":{"index":1,"total":1}, "piece":{"index":1,"total":1} }
  ```
  No encontrado → `200` con `resolved:false` y nulos. `revoked` sale de `labels_emitted.revoked_at`.
  `order_number` viaja aun con `resolved:false`.
- **Modelo confirmado:** QR = 100% offline Ed25519 (no llama a `/resolve`; sigue el best-effort
  `POST /app/labels/verify`); `/resolve` = SOLO Code128; sin red → se rechaza el Code128.
- **`unit`/`piece` anidados (canónico):** `{index,total}` como objeto, o `null`. (El backend aclaró que
  los planos `unit_index`… de su primer mensaje fueron un error de redacción; la API nunca los devolvió.)
  `LabelResolution.fromJson` lee la forma anidada como canónica y deja el fallback plano por las dudas.
  La app NO usa esos campos hoy, igual.

## Lo cableado en la app (sin regen, Dio crudo)

- `lib/core/labels/label_resolver.dart`: modelo `LabelResolution` + `LabelResolver` (GET por Dio crudo) +
  `labelResolverProvider` + helper `resolveLabelId` (devuelve `null` sin red → se rechaza).
- `kLabelScanFormats = [qrCode, code128]` (`core/scanning/scanner_screen.dart`) en los escaneos de
  ETIQUETA (chofer POD/carga-descarga, tienda recepción/retiro, transportista pickup/deliver). NO toca
  el QR de confirmación del cliente ni el EAN de productos.
- Rama Code128 en `resolveUnitScan` (tienda), `verifyUnitLabel` (chofer) y `verifyLabelQr`
  (transportista): QR firmado → offline; si no → `resolveLabelId`. Mensajes: no reconocida / **anulada**
  (revoked) / **sin señal** (sin red).
- Tests: `label_resolver_test`, `unit_scan_test` (casos Code128), `code128_resolve_scan_test`
  (chofer+transportista), seam `test/support/fake_label_resolver.dart`, e2e `fake_backend.resolveLabel`.

### Pedido original (contexto)

## Contexto

El backend hizo la simbología de la etiqueta configurable (setting `labels.symbology`): QR, **Code128
(Zebra)** o ambos. El escaneo de la app debe aceptar **ambas** simbologías, no solo QR.

- **QR:** contenido = JSON firmado → la app verifica la firma **Ed25519 OFFLINE** (sin cambios;
  `LabelPayload::canonical()` NO cambió, el vector `test/fixtures/label_test_vector.json` sigue válido,
  no hay que subir `v` ni regenerar). De ahí sale `payload.id = label_id`.
- **Code128:** el valor escaneado **ES directamente el `label_id`**, SIN firma → **no se puede verificar
  offline**. Se resuelve contra el backend con el read-side existente `ResolveLabelUnit(label_id)`.

**Decisión del dueño (aprobada):** Code128 se valida **ONLINE** (sin anti-fraude offline); el QR sigue
offline. Sin red, un Code128 se **rechaza** con aviso claro en terreno.

En web ya existe: admin → Operaciones → «Escanear etiqueta» (BarcodeDetector QR+Code128) →
`GET /cockpit/label/resolve?code=<escaneado>`. Falta el equivalente `/app/*` para la app de campo.

## Lo que la app necesita (contrato EXACTO)

1. **Ruta** del endpoint `/app/*` (Bearer) que resuelve por el valor escaneado. ¿`GET
   /app/labels/{labelId}/resolve`, `GET /app/labels/resolve?code=<...>`, u otra? Literal.
2. **Entrada:** ¿solo `label_id` (Code128) o también el valor crudo del QR? Plan de la app: extraer
   `payload.id` del QR y mandar siempre el `label_id`. Confirmar, o si prefieren el `code` crudo.
3. **Respuesta 200:** shape JSON completo + ejemplo real (`unit_id`, `shipment_id`, `order_reference`,
   `label_status` pending|emitted|revoked, `destination`, flags de validez…). Es `LabelUnitResolution`.
4. **Errores:** HTTP + body para label inexistente/inválido vs **revocado** vs "no es de este pedido"
   (la app los muestra distinto en terreno, como hoy distingue "firma inválida" de "clave desconocida").
5. **Scope/ability** y rate limit.
6. **Disponibilidad:** ¿ya está en el working tree de `feature/commerce-fase0` en el server dev?
   ¿Se puede probar en vivo ya? ¿La ruta/shape puede cambiar al mergear?
7. **Confirmar el modelo:** QR = offline (no llama al endpoint; se mantiene el best-effort
   `POST /app/labels/verify`); `/resolve` = SOLO Code128.

## Plan app (cuando llegue el contrato)

- `kLabelScanFormats = [qrCode, code128]` compartido en los ~8 sitios de escaneo de etiqueta
  (chofer POD/scan_units/fallida, tienda recepción/retiro, transportista pickup/deliver).
- Rama en la resolución (`LabelScanner`): si el contenido parsea como QR firmado → camino offline
  actual; si no → tratarlo como `label_id` crudo y resolver por `/resolve` (Dio crudo, sin regen),
  marcándolo como "verificado por servidor" (no offline). Sin red → rechazo con mensaje claro.
- No regenera el cliente ni toca `LabelPayload::canonical()`.
