---
name: generated-code-build-caveats
description: "Tras cambiar tablas Drift o modelos de API hay que correr build_runner o VS Code tira \"Errors exist\"/clases undefined; y un parche a mano en modelos generados del API se pisa al regenerar."
metadata:
  node_type: memory
  type: project
  originSessionId: b09fb122-a063-448a-9f98-c86b13899a10
  modified: 2026-11-12T08:44:32.662Z
---

Dos trampas vistas el 2026-10-14 al destrabar el build de la app:

1. **Código generado desactualizado = errores fantasma.** Si se agrega una tabla Drift (`lib/core/offline/app_database.dart`) o cambian modelos del API y no se corre `dart run build_runner build`, el proyecto no compila: VS Code muestra el cartel **"Errors exist in your project"** y el analyzer marca clases `undefined` (`PendingPhoto`, `DriverRoute`, etc.) que en realidad sí existen. Fix: regenerar con build_runner; si sigue, `Dart: Restart Analysis Server`. Esos "errores" suelen ser estado intermedio mientras se regeneran los `.g.dart`.

3. **Un campo REQUERIDO que el backend deja de mandar rompe TODA la pantalla (nov 2026).** El backend quitó `revoked` de las etiquetas (contrato de etiquetas permanentes) y `EmittedLabel.revoked` era `required` → `fromJson` explotaba y el preparador veía **"No se pudo cargar"** en CUALQUIER pedido. El 200 del backend era perfecto; el bug era de deserialización. **Diagnóstico rápido:** si una pantalla dice "no se pudo cargar" pero `curl` al endpoint da 200, comparar las claves del JSON real contra los campos `required` del modelo generado. **Fix:** volver el campo opcional con default (`this.x = false` + `json['x'] as bool? ?? false` en el `.g.dart`) y dejar comentado que se resuelve solo al regenerar. Test de regresión con el JSON REAL del backend.

4. **`MetaSealed` es INSERVIBLE para paginar (nov 2026).** Dos bugs independientes: (a) deserializa en **camelCase** (`json['perPage']`, `json['nextCursor']`) mientras el backend manda snake_case; (b) la PRIMERA variante del sealed solo exige `count` y el deserializador prueba en orden, así que **siempre gana ella** y las variantes con paginación/cursor son inalcanzables aunque se arregle (a). Resultado: ninguna pantalla puede leer `next_page`/`next_cursor`/`has_more`. **Workaround usado:** paginar por NÚMERO DE PÁGINA con heurística "página completa ⇒ puede haber más" (cuesta un GET vacío al final). El backend ya unificó el contrato en un único `ListMeta` snake_case; **al regenerar el cliente desaparece `MetaSealed` y hay que sacar la heurística**.

2. **Parche a mano en modelos generados del API se pierde al regenerar.** Había 4 respuestas (`get_app_carriers_response`, `get_app_shipments_response`, `get_app_shipments_low_confidence_addresses_response`, `get_channels_promises_delivery_response`) con `meta` no-nullable y constructor opcional → no compilaba. Se parchó a `MetaSealed? meta`, **pero** `dart run swagger_parser` pisa esos archivos (`// GENERATED CODE - DO NOT MODIFY BY HAND`). **Fix de fondo pendiente en el backend:** que `openapi/v1.json` marque `meta` opcional/nullable correctamente, o ajustar la plantilla de swagger_parser. Regla #5: los DTOs del API salen de `openapi/`, no se escriben a mano. Ver [[app-scope-backend-consumer]].
