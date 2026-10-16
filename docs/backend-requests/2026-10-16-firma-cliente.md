# Pedido al backend: firma digital del cliente en la prueba de entrega

**De:** app interna (logistics-app) · **Para:** agente/equipo del repo `logistics` (backend)
**Fecha:** 2026-10-16 · **Prioridad:** media (la app ya funciona con un fallback)

## Contexto

En la prueba de entrega (POD) del chofer se reemplazó "Firma en papel (sin QR)" por **"Firma del
cliente"**: el cliente firma con el dedo en un pad a pantalla completa. La app exporta la firma a
PNG (trazo negro sobre blanco, recortado al área firmada, unas decenas de KB) y la sube por la
misma cola offline de evidencias que la foto de entrega (`POST /app/deliveries/photos`, multipart,
idempotente). El POD (`POST /app/deliveries/proof-of-delivery`) viaja con
`confirmation = "FIRMA_DIGITAL"`. Se mantiene la opción de escanear el QR del cliente y la foto de
entrega sigue siendo obligatoria.

## Lo que falta

1. **`kind = signature` en `POST /app/deliveries/photos`.** Hoy el enum es `pod | damage` (request
   y response). Mientras no exista, la app sube la firma como `kind = pod` (lo más cercano), así que
   en el disco de evidencias queda mezclada con las fotos de entrega y no se distingue cuál es la
   firma. Pedido:
   - agregar `signature` al enum de `kind` (request y `data.kind` de la respuesta);
   - aceptar `image/png` (la firma es PNG; las fotos son JPEG);
   - guardarla en el disco de evidencias con su propio prefijo/carpeta.
2. **Ligar la firma al POD.** La subida es asíncrona (offline-first): el POD puede llegar antes que
   la imagen. Igual que con la foto, el backend debería asociar la firma al envío por `shipment_id`
   y exponerla en `Delivery` (p. ej. `pod_signature_path` / `pod_signature_url`, nullable), para
   que supervisor/atención al cliente la vean junto a la foto.
3. **Marcador `FIRMA_DIGITAL`.** Confirmar que `confirmation` lo acepta como valor válido (hoy es
   texto libre: código del QR del cliente o el marcador). Si el backend valida el QR contra el
   envío, `FIRMA_DIGITAL` debe quedar exento de esa validación, como lo estaba `FIRMA_PAPEL`.
4. **Contrato.** Actualizar `openapi/v1.yaml` para regenerar el cliente: la app solo cambia la
   constante `kSignatureEvidenceKind` (`lib/features/driver/presentation/pod_screen.dart`) de
   `pod` a `signature` y el mapeo de `kind` en `PhotoUploadQueue`.

## Qué hace la app mientras tanto

- Sube la firma con `kind = pod` y el POD con `confirmation = FIRMA_DIGITAL`.
- Si no puede escribir la imagen en el teléfono, registra igual la entrega (no se frena al chofer).
