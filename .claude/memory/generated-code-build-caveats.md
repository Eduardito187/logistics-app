---
name: generated-code-build-caveats
description: "Tras cambiar tablas Drift o modelos de API hay que correr build_runner o VS Code tira \"Errors exist\"/clases undefined; y un parche a mano en modelos generados del API se pisa al regenerar."
metadata:
  node_type: memory
  type: project
  originSessionId: b09fb122-a063-448a-9f98-c86b13899a10
  modified: 2026-10-15T06:43:18.317Z
---

Dos trampas vistas el 2026-10-14 al destrabar el build de la app:

1. **Código generado desactualizado = errores fantasma.** Si se agrega una tabla Drift (`lib/core/offline/app_database.dart`) o cambian modelos del API y no se corre `dart run build_runner build`, el proyecto no compila: VS Code muestra el cartel **"Errors exist in your project"** y el analyzer marca clases `undefined` (`PendingPhoto`, `DriverRoute`, etc.) que en realidad sí existen. Fix: regenerar con build_runner; si sigue, `Dart: Restart Analysis Server`. Esos "errores" suelen ser estado intermedio mientras se regeneran los `.g.dart`.

2. **Parche a mano en modelos generados del API se pierde al regenerar.** Había 4 respuestas (`get_app_carriers_response`, `get_app_shipments_response`, `get_app_shipments_low_confidence_addresses_response`, `get_channels_promises_delivery_response`) con `meta` no-nullable y constructor opcional → no compilaba. Se parchó a `MetaSealed? meta`, **pero** `dart run swagger_parser` pisa esos archivos (`// GENERATED CODE - DO NOT MODIFY BY HAND`). **Fix de fondo pendiente en el backend:** que `openapi/v1.json` marque `meta` opcional/nullable correctamente, o ajustar la plantilla de swagger_parser. Regla #5: los DTOs del API salen de `openapi/`, no se escriben a mano. Ver [[app-scope-backend-consumer]].
