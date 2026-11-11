---
name: native-share-evidence
description: "Compartir por el menú NATIVO del móvil (WhatsApp, etc.): etiquetas, firmas y fotos de evidencia — servicio core/sharing con seam para tests."
metadata:
  node_type: memory
  type: project
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-05T21:35:56.983Z
---

Pedido del dueño (2026-11-05): botón **Compartir** con el share nativo del móvil (WhatsApp, correo,
donde sea) para **etiquetas**, **firmas de clientes** y **fotos de documentos/evidencia**. Implementado:

- Dep: `share_plus: ^10.1.4` (API `Share.shareXFiles`, estable con Flutter 3.32 / Dart 3.8; NO subir a 11.x sin revisar API).
- `lib/core/sharing/share_service.dart`: `ShareService` (seam, `shareServiceProvider`) con `shareImagePng(bytes, filename, text)` (vuelca a temp y comparte) y `shareFile(path, text)`. `PlatformShareService` = real.
- `lib/core/sharing/capture_boundary.dart`: `captureBoundaryPng(GlobalKey, pixelRatio)` rasteriza un `RepaintBoundary` a PNG; inyectable por `boundaryCapturerProvider` (tests no rasterizan de verdad).
- Tests: `test/support/fake_share_service.dart` (`FakeShareService`/`SharedItem`) + `test/features/sharing/share_feature_test.dart`.

**Dónde está cableado:**
- **Etiqueta** (`label_preview_sheet.dart`): el `_LabelCard` va en `RepaintBoundary`; botón "Compartir" (destacado, `AppIcon.send`) captura→comparte PNG. La hoja pasó a `ConsumerStatefulWidget`.
- **Firma del cliente** (`driver/.../pod_screen.dart`): "Compartir firma" (PNG en memoria).
- **Foto de evidencia**: POD chofer (`pod_screen.dart`, `shareFile(path)`) y recojo en tienda (`pickup_pod_cards.dart` `PickupPhotoCard.onShare` ← `pickup_pod_screen.dart`).

OJO: no hay ícono dedicado "share" en el catálogo; se usa `AppIcon.send` (enviar/paper-plane). Si el dueño quiere el glifo de compartir, agregarlo con la skill [[portable-memory-skills]] animated-app-icons. Ver [[labeling-order-multishipping]], [[product-ux-decisions]].

**ANTI-FRAUDE — evidencia ligada al cliente, Phase 1 cableada (nov 2026):** backend `logistics-8e` entregó `POST /app/deliveries/evidence` (multipart: shipment_id, kind∈{pod,damage,signature,id_document}, photo, + customer_id/document_id/customer_name/customer_phone/lat/lng/captured_at opcionales, Idempotency-Key → 201 DeliveryEvidenceCollection con validation_status pending|ok|review|mismatch; hash SHA-256 + auditoría + OCR carnet vs document_id en sidecar async). Rutas en execution.php, en openapi (working tree, sin commit). **App cableada SIN regen** (Dio crudo multipart): `PhotoUploadQueue.enqueue(clientSnapshot?)` guarda el snapshot como **sidecar JSON `<id>.snapshot.json`** junto a la foto (NO se agregó columna Drift: **build_runner está roto** por `retrofit_generator 10.2.0` vs `retrofit 4.10.0` — el cliente API se regenera con otro toolchain, no con build_runner; evité tocar Drift). `_upload` rutea `signature`/`id_document` al endpoint nuevo con el snapshot + Idempotency-Key=id; `pod`/`damage` siguen en `/app/deliveries/photos` (estable). `sweepOrphanFiles`/`purgeFailed` limpian el sidecar. POD (`pod_screen.dart`): firma `kind=signature` (antes 'pod'), nueva sección "4. Documento del cliente (opcional)" (`id_document`), snapshot `{customer_name,customer_phone,lat,lng,captured_at}`, compartir del documento. **Phase 2 (validation status) CODEADA code-only (sin compilar, el dueño deshabilitó flutter):** `lib/features/driver/domain/entities/delivery_evidence.dart` (modelo `DeliveryEvidenceItem` + enum `EvidenceValidation`), `data/datasources/delivery_evidence_data_source.dart` (GET `/app/deliveries/{shipmentId}/evidence` por Dio crudo + `deliveryEvidenceProvider` family), y `_EvidenceSection` en `delivery_sheet.dart` (hoja de detalle) que muestra por evidencia: Firma/Documento/Foto + pastilla Validando…/Validado/Revisar/No coincide; se oculta si no hay evidencia. Test `delivery_evidence_data_source_test.dart`. Verificado SOLO con getDiagnostics del IDE (sin `flutter test`). **Pendientes:** persistir trazos crudos de la firma (x,y,t) — necesita campo en el backend; y el regen tipado (emit-por-orden, sesiones, evidencia, destino de parada) cuando el dueño autorice el push de `feature/commerce-fase0` + rehabilite flutter.
