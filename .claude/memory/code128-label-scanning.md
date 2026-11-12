---
name: code128-label-scanning
description: "Escaneo de etiquetas acepta QR (offline Ed25519) Y Code128/Zebra (label_id → resuelve online por /app/labels/{id}/resolve); seams, enums parchados, consumidores."
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-11T14:07:38.686Z
---

Nov 2026: la etiqueta de bulto tiene **simbología configurable** (setting backend `labels.symbology`: QR,
Code128/Zebra, o ambos). El escaneo de la app debe aceptar **las dos**:

- **QR** = JSON firmado → verificación **offline Ed25519** (sin cambios; `LabelPayload::canonical()` y el
  vector `test/fixtures/label_test_vector.json` siguen válidos). `payload.id` = `label_id`.
- **Code128** = el valor escaneado **ES el `label_id`**, SIN firma → NO se verifica offline → se resuelve
  **ONLINE** contra `GET /app/labels/{labelId}/resolve` (siempre 200; mirar `resolved`, NUNCA 404; trae
  `unit_id, shipment_id, sku, order_number, revoked`, y `unit/piece` ANIDADOS `{index,total}`). Sin red el
  Code128 se **rechaza** con aviso. Decisión del dueño: Code128 valida online, QR sigue offline.

**Cableado app (Dio crudo, sin regen):** `lib/core/labels/label_resolver.dart` = modelo `LabelResolution`
(fromJson acepta anidado y plano) + `LabelResolver` (GET por `dioProvider`) + `labelResolverProvider` +
helper `resolveLabelId(ref, labelId)` (devuelve `null` sin red). `kLabelScanFormats = [qrCode, code128]`
(`core/scanning/scanner_screen.dart`) reemplazó `[qrCode]` en TODOS los escaneos de ETIQUETA (chofer
POD/carga-descarga, tienda recepción/retiro, transportista pickup/deliver). **NO** se tocó el QR de
confirmación del cliente ni el EAN de productos.

**Rama de resolución en los 3 consumidores** (`store/unit_scan.dart` `resolveUnitScan`; `driver_common.dart`
`verifyUnitLabel`; `carrier_scan_support.dart` `verifyLabelQr`): si el contenido parsea como QR firmado →
camino offline; si NO → `resolveLabelId`. **OJO diseño:** detectar la estructura QR con
`SignedLabel.fromQrContent` ANTES de resolver — un QR válido SIN claves lanza `LabelFormatException` igual
que un no-QR, y NO debe mandarse a resolver online (el carrier tenía este bug). Mensajes: no reconocida /
"Etiqueta anulada" (revoked) / "Sin señal para validar". `UnitScan` ganó campos `online/revoked/unreachable`.

**Enums parchados a mano (aditivo, idéntico al regen):** `RecordOdometerRequestSource` y
`OdometerReadingSource` ganaron `arrival`; el `label_id` no requirió enum. El endpoint `/resolve` y el
`revoked`/`order_number` los entregó el backend (`logistics-1a`); la ruta está en working tree (regen
tipado pendiente, el Dio crudo funciona).

**Seams de test:** `test/support/fake_label_resolver.dart` (`FakeLabelResolver` con modos `resolutions`
sembradas, `offline:true` lanza, `echo:true` reconoce el label_id como unit_id). En e2e, `fake_backend`
tiene `resolveLabel()` (echo) y un handler regex `^/app/labels/(.+)/resolve$`. Los harness de store/carrier
que escanean códigos PLANOS (ej. `unit-1`, `BULTO-2`) necesitan
`labelResolverProvider.overrideWithValue(FakeLabelResolver(echo:true))`. Ver [[labeling-order-multishipping]]
y [[test-battery-and-infra]].
