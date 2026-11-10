# Evidencia de entrega ligada al CLIENTE + validación anti-fraude

- **De:** app (logistics-app) — por pedido del dueño
- **Para:** backend (logistics) — sesión `logistics-8e`, con **agentes en paralelo**
- **Fecha:** 2026-11-05
- **Prioridad:** Alta
- **Estado:** Delegado al backend (investigación + implementación en paralelo).

## Objetivo

Prevenir **fraude** en las entregas. Hoy la firma del cliente y las fotos de documento se suben como
evidencia **ligadas solo al envío** (`kind=pod`), sin relación fuerte con la identidad del cliente. Se
necesita que **firmas y fotos de documento del cliente se guarden LIGADAS AL CLIENTE** (entidad customer)
y que el backend **valide** esa evidencia contra el cliente correcto.

## Qué hace hoy la app

- Firma del cliente (PNG en pantalla) y foto de evidencia/documento → `POST /app/deliveries/photos`
  (`kind` hoy = `pod | damage`; la firma se sube como `pod` como workaround, ver
  [firma-cliente](2026-10-16-firma-cliente.md)).
- La app ya puede **compartir** firma y fotos por el share nativo (WhatsApp, etc.).

## Lo que debe implementar el backend (exigente, DoD verde)

1. **Modelo de datos — evidencia ligada al CLIENTE:**
   - Persistir cada evidencia (firma, foto de documento/carnet, foto POD) asociada a: el **envío/entrega**
     Y el **cliente** (customer: id, `document_id`, nombre, teléfono).
   - **Integridad / tamper-evidence:** hash del archivo (p. ej. SHA-256), registro de auditoría inmutable
     (quién/cuándo/dónde + GPS del POD), para que no se pueda intercambiar una evidencia por otra.
2. **Nuevos `kind` de evidencia:** `signature` y `id_document` (hoy solo `pod|damage`). Actualizar el
   contrato de `POST /app/deliveries/photos` (o endpoint dedicado) + `openapi/v1.yaml`.
3. **Validación anti-fraude:**
   - **Firma del cliente:** guardar una firma de referencia por cliente (la primera/conocida) y, en cada
     entrega, devolver una **señal de verificación** (similitud/aprobado-dudoso-rechazado), o al menos
     marcar discrepancias para revisión.
   - **Documento (carnet de identidad BO):** OCR del número de documento y **cruce contra el
     `document_id`** del cliente en el sistema; marcar si no coincide.
   - **Face/foto (opcional, futuro):** match contra foto del cliente si existe.
   - Todo **on-premise / self-host** (no mandar PII del cliente a nubes de terceros).
4. **Investigación OPEN-SOURCE (con agentes en paralelo):** evaluar y recomendar stack libre para:
   - Verificación de **firma manuscrita** (p. ej. redes siamesas/SigNet, OpenCV, libs de signature
     verification).
   - **OCR + validación de documento** (Tesseract, PaddleOCR; parseo de carnet BO / MRZ si aplica).
   - **Face match / liveness** opcional (p. ej. InsightFace), solo si suma.
   - Entregar una **comparativa corta** (licencia, madurez, factibilidad on-prem, costo/infra) + **stack
     recomendado** y un ADR de decisión.
5. **Offline-first:** la subida de evidencia sigue por la cola idempotente de la app; la validación puede
   ser asíncrona (worker) y su resultado consultable.

## Contrato que espera la app

- `POST` de evidencia con `kind ∈ {pod, damage, signature, id_document}` + `customer`/`client_id`
  asociable, devolviendo un id de evidencia.
- Un campo/endpoint para consultar el **resultado de validación** por entrega/cliente (estado:
  `pending|ok|review|mismatch` + detalle).
- Todo en `openapi/v1.yaml` (aditivo), para que la app regenere y consuma.

## Criterio de aceptación

Evidencia (firma + documento) persistida y recuperable **por cliente**, con hash de integridad y
auditoría; un endpoint devuelve el estado de validación anti-fraude; investigación open-source entregada
con recomendación; DoD verde (tests, PHPStan, Pint) y openapi actualizado.
