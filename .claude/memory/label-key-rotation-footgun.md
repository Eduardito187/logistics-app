---
name: label-key-rotation-footgun
description: "nov 2026 — 'etiqueta no válida' en staging = la clave de firma Ed25519 key_id=1 se regeneró en un deploy (reuso de id); causa raíz, recuperación agotada, re-emisión y el fix de prod (registro append-only + guardia)"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-12T04:26:36.465Z
---

**Síntoma:** al escanear etiquetas válidas de SCZ-261111-01 (emitidas 10-nov) la app decía "etiqueta no válida". El app estaba CORRECTO (canónico byte a byte, pasa el vector de contrato); la firma no validaba contra la pública publicada por staging.

**Causa raíz (confirmada por el backend desde su repo):** `scripts/staging/render-env.sh` GENERA una Ed25519 fresca si `STAGING_ENV_EXTRA` no trae `LABELS_SIGNING_KEY`. La persistencia en `~/.logistics-staging/labels-signing.env` es RECIENTE; antes cada deploy generaba una clave NUEVA bajo el **mismo key_id=1** → cada deploy invalidaba lo firmado antes. El deploy de hoy (11-nov) recreó el archivo 21:17 y los contenedores 22:46 → nueva pública `1:tO1y5ZbB8Sek8Vjj+uIJVKY62pW0pNdlIAzE8ZjnaYc=` que no valida lo del 10-nov.

**Recuperación de la clave vieja (K_old): AGOTADA, imposible.** Investigado por ssh a staging (ver [[staging-server-access]]): `labels_emitted` guarda `key_id` + `signed_json` (firma) pero **NO la pública**; no hay tabla de claves; no hay env/backup previo; no hay contenedor viejo detenido (compose los borró); no hay repo git del deploy. De Ed25519 **no se deriva la pública desde firmas**. K_old solo viviría donde se generó el secret original (los secrets de GH no se leen de vuelta). Veredicto del dueño: **re-emitir** (staging = datos de prueba).

**Procedimiento de re-emisión (sirvió, verificado):** login app staging `preparador@dismac.test`/`password123` (cuentas dev espejadas en staging) → `POST /app/orders/{n}/labels/reprint {reason}` → `POST /app/orders/{n}/labels {}` (emisión). Verificar las nuevas con el verificador real: `LabelVerifier.fromConfig('1:tO1y5Zb…').verify(SignedLabel.fromQrContent(signed_json))` → `VerificationResult.valid`. SCZ-261111-01 quedó con 2 activas nuevas (org CD-SCZ-01, ln swap vs viejas) que el app acepta.

**BUG detectado y ARREGLADO (backend, falta deploy):** en staging `/labels/reprint` **solo REVOCABA, no re-emitía** (201 pero 0 activas) — por eso hubo que llamar `/labels` aparte. Causa: el handler de reprint siempre pasaba las líneas del body; con body `{reason}` (sin líneas) emitía un lote de 0 líneas. Fix: `ReprintOrderLabelsHandler` ahora, sin líneas, re-emite derivando del pedido (revocación en la misma transacción). El app (`_reprintBatch`) ya llama solo con `{reason}` → correcto; al desplegar, "Reemitir" dejará activas sin paso extra.

**DECISIÓN POSTERIOR del dueño (modelo ABIERTO, nov 2026):** una etiqueta impresa NUNCA se descarta por un tema de claves. El backend pasó a **etiquetas abiertas** (`LABELS_OPEN=true`, o automático sin `LABELS_SIGNING_KEY`): emite con `k:0`, sin firma, y la autenticidad la da el **registro/pertenencia** (el `id` resuelve y pertenece al envío/ruta), no la criptografía. Tradeoff asumido: el QR es copiable (frena ids inventados, no la fotocopia de uno real) — aceptable para app interna. El modo firmado sigue disponible con el registro append-only. **App adaptada** (`VerificationResult.open`, `LabelPayload.openKeyId=0`/`isOpen`, `LabelScanner.scan` no verifica k:0 ni necesita claves, `SignedLabel` ignora `s` en abiertas; compat k>0): etiquetas abiertas NUNCA se rechazan por firma; la pertenencia se valida con `driverShipmentUnitsProvider`. Verificado: analyze limpio + tests verdes (caso k:0). Pendiente: deploy staging con LABELS_OPEN sin regenerar la clave.

**Fix de PROD (aprobado por el dueño, construido por el backend, verde en dev, falta commit+deploy):** tabla `label_signing_keys` + `SigningKeyRegistry` append-only + **guardia al boot** (si una clave nueva deriva otra pública para un key_id ya registrado → RuntimeException, NO firma; habría abortado este deploy) + verificador que prueba VARIAS públicas por el mismo id + bundle que sirve registro+anteriores+activa. Rotación real = key_id NUEVO. El app YA soporta varias públicas por id ([[code128-label-scanning]], LabelVerifier). **Ops/dueño:** fijar que `STAGING_ENV_EXTRA` no pise la clave ya persistida, para que tO1y5Zb sea estable entre deploys.

Relacionado: [[pod-scanner-vehicle-hardening]], [[test-pass-detected-flaws]].
