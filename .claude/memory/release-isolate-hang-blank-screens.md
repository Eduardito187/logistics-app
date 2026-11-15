---
name: release-isolate-hang-blank-screens
description: "nov 2026 — \"a veces no carga el logo / la lista del preparador sale vacía hasta cerrar y abrir\": en RELEASE flutter_svg y Dio usan isolates que en algunos arranques no responden; fix = .vec precompilado + decodificar en el hilo principal"
metadata:
  node_type: memory
  type: project
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-15T05:19:15.404Z
---

**Síntoma (dueño, 2026-11-15, teléfono real):** a veces el login abre SIN logo y "Pedidos por preparar" sale
vacío; se arregla cerrando y abriendo la app. Nunca pasa en tests ni en debug.

**Causa (hipótesis fuerte, no reproducida por mí):** dos cosas que SOLO en release van a un isolate
(`compute`): (1) `SvgPicture.asset` compila el SVG al vuelo; (2) Dio (`FusedTransformer`, umbral 50 KB)
decodifica ahí las respuestas grandes, p. ej. la lista de 50 pedidos. Si el isolate no responde en ese
arranque: logo en blanco y la lista cargando para siempre (y el loader, que es un SVG, tampoco se ve →
"vacío"). En debug ambos corren en el hilo principal, por eso no se veía.

**Fix aplicado:**
- `lib/core/brand/brand_vector.dart` (`BrandVector`): carga `assets/brand/<x>.svg.vec` precompilado, sin
  isolate. NO usar `SvgPicture.asset` para la marca. Al cambiar un SVG regenerar:
  `dart run vector_graphics_compiler -i assets/brand/x.svg -o assets/brand/x.svg.vec`.
- `dio_client.dart`: `dio.transformer = FusedTransformer(contentLengthIsolateThreshold: -1)`.

**How to apply:** ante un "a veces queda en blanco / cargando hasta reiniciar" solo en dispositivo, buscar
primero qué corre en isolate en release. Falta confirmar en el teléfono que el fix lo resuelve. Ver
[[perf-rebrand-stability-fixes]].
