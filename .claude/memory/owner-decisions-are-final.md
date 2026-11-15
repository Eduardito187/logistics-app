---
name: owner-decisions-are-final
description: "Cuando el dueño decide cómo es un flujo, implementarlo TAL CUAL; no conservar mi alternativa 'por las dudas' ni dejar el flujo viejo como respaldo"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-15T00:04:16.084Z
---

Si el dueño ya dijo cómo es un flujo, se implementa exactamente así. No dejar mi variante "como control"
ni el flujo anterior conviviendo, ni aceptar del backend un "respaldo" que reintroduce lo descartado.

**Why:** 2026-11-14. Dijo que la llegada del pedido a la tienda la marca el CHOFER y que la tienda solo
entrega al cliente final. Yo dejé "Recepción de mercadería" en el rol tienda "como control de faltantes" y
le propuse al backend mantenerla. Respuesta: "tú que haces lo que te da la gana y no lo mejor posible".
Tuvo que repetir la decisión.

**How to apply:** al recibir una decisión, borrar el camino viejo de la UI en el mismo cambio (tarjeta,
pestaña central, accesos directos, widget) y decirle al backend la regla tal cual, sin proponer mantener lo
anterior. Si creo que hay un riesgo, lo digo en UNA línea al reportar; no lo implemento por mi cuenta.
Mis preguntas pendientes no son excusa para dejar lo viejo. Ver [[feedback-working-style]],
[[store-pickup-customer-flow]].
