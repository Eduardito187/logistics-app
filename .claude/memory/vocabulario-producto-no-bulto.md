---
name: vocabulario-producto-no-bulto
description: "PROHIBIDA la palabra \"bulto/bultos\" en la app; siempre \"producto/productos\" (regla del dueño)"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-12T19:25:11.748Z
---

**Nunca** usar "bulto" ni "bultos" en la app DisTrack: siempre **"producto"/"productos"**. Aplica a TODO lo que ve el usuario (textos de UI en español, snackbars, títulos, etiquetas de botones, mensajes de error, nombres de pantallas) y también a comentarios/documentación en español para que no se recaiga.

**Why:** es el vocabulario del negocio que el dueño quiere en boca de choferes y personal de tienda; "bulto" es jerga interna de logística y confunde. El dueño lo pidió varias veces (también existe el pedido al backend `docs/backend-requests/2026-10-23-productos-nombre-sku-no-bulto.md`), y en nov 2026 señaló que todavía quedaban textos sin corregir.

**How to apply:** al escribir CUALQUIER texto nuevo, usar "producto/productos". Antes de dar por terminada una pantalla, `grep -ri "bulto" lib/ test/` debe volver vacío en strings de UI. Ojo: los identificadores de código en inglés (`unitId`, `unit_ids`, `UnitTile`, `unitsTotal`) NO se tocan — la regla es sobre el idioma que ve el usuario. Ver [[pod-scanner-vehicle-hardening]].

**Regla hermana (12-nov): NO mostrar la palabra literal "SKU".** El dueño pidió ver el VALOR del SKU pero no la palabra "SKU" antes. Mal: `'SKU ${label.sku} · Línea 2'` → se ve "SKU BAS-QUEEN · Línea 2". Bien: `'${label.sku} · Línea 2'` → "BAS-QUEEN · Línea 2". Corregido en `unit_tile.dart`, `dispatch_lines_body.dart`, `label_preview_sheet.dart` (y sus tests). El identificador `sku` en código no se toca; es solo el texto visible. Al escribir una fila de producto, mostrar el valor del SKU pelado (es autoexplicativo), nunca prefijado con "SKU ".
