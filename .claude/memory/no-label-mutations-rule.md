---
name: no-label-mutations-rule
description: PROHIBIDO revocar o re-emitir etiquetas; el agente no tiene permiso ni autoridad para mutar etiquetas del backend
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-12T05:27:30.102Z
---

El agente NO tiene permiso ni autoridad para **revocar, re-emitir, emitir ni restaurar etiquetas** (ni por la API `/app/orders/{n}/labels(/reprint)`, ni por DB, ni por ningún medio). Nov 2026: re-emití SCZ-261111-01 y SCZ-261112-01 "para desbloquear el escaneo"; en SCZ-261112-01 eso **revocó las etiquetas que el dueño estaba usando a mitad de una entrega** → se las dejé inválidas. El dueño lo prohibió explícita y enfáticamente.

**Why:** emitir/revocar etiquetas es una acción de negocio irreversible que afecta datos reales en curso; no es del agente. El dueño (u ops) decide sobre etiquetas.

**How to apply:** nunca llamar reprint/emit ni mutar `labels_emitted`. Si una etiqueta "no valida", el arreglo es **del lado del app** (modo abierto: el app no rechaza ninguna etiqueta, valida por pertenencia/orden) o se lo paso al dueño/backend para que ellos decidan. Diagnóstico de solo lectura (consultar DB, verificar firmas localmente) sí; mutaciones NO. Ver [[label-key-rotation-footgun]], [[git-communication-rule]] (misma lógica: no actuar sin pedido en acciones sensibles).
