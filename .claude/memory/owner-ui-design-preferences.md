---
name: owner-ui-design-preferences
description: "Preferencias de diseño que el dueño corrigió varias veces (nov 2026): selects, botón principal fijo al pie, formularios a pantalla completa, fotos como recuadro con vista previa, línea de tiempo en tarjetas, nada cortado ni UUID, nunca vacío mientras carga"
metadata:
  type: feedback
---

El dueño revisa la app en el teléfono y devuelve capturas con "se ve horrible". Lo que pidió, siempre igual:

- **Selects** para filtros y opciones (ciudad, estado, rol, destinatario, estado del camión). Nada de chips
  ni de un campo de texto donde hay una lista conocida.
- **Botón principal FIJO al pie** de la pantalla; no al final del scroll ("es feo tener que deslizar todo").
- **Formularios = pantalla completa** por secciones, no un diálogo con campos apilados.
- **Fotos = recuadro que se toca**, con vista previa; anverso y reverso donde corresponde. Sin textos de
  botón tipo "Sacar foto del anverso".
- **Listas de pasos/paradas = línea de tiempo en tarjetas.** Ningún dato cortado.
- **Sin UUID** a la vista, el SKU sin la palabra "SKU", foto del producto, hojas del alto del contenido.
- **Nunca el estado vacío mientras carga** (le molestó ver "Sin notificaciones" un instante); caché para
  que volver a una pantalla sea instantáneo.
- Mapas: el camión visto desde arriba, el mismo en chofer y flota.

**Why:** lo usan personas en la calle y en depósito, con una mano; y el dueño juzga el producto por cómo se
ve en su teléfono. Cada vez que volví a un `AlertDialog` con campos, a chips o a un botón al final de la
lista, lo devolvió.

**How to apply:** al tocar o crear una pantalla, pasar esta lista ANTES de entregarla, aunque no la haya
pedido para esa pantalla. El detalle con los widgets a reusar está en el skill `flutter-feature`. Ver
[[product-ux-decisions]], [[planner-role-and-planning]], [[owner-decisions-are-final]].
