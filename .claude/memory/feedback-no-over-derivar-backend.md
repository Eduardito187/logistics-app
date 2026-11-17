---
name: feedback-no-over-derivar-backend
description: "el dueño se enoja cuando derivo todo al backend sin arreglar lo mío; antes de decir 'es del backend' hay que verificar que la app de verdad no puede"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 9a85d4dc-6dee-4d1d-8426-868a6db4e45d
  modified: 2026-11-16T15:20:49.013Z
---

El dueño me corrigió fuerte (16-nov-2026, y ya antes): "te he dado una orden de poner a trabajar en las
correcciones y no haces un carajo" / "los que sean tuyos soluciona y lo que dependa del backend derivaselo
pero quiero soluciones" / "¿nuevamente le asignaste trabajo al backend?". El patrón malo: triagear una lista
de bugs de dispositivo y mandar casi todo al backend sin verificar que la app realmente no puede resolverlo.

**Por qué:** el dueño quiere soluciones de mi lado, no un reporte de pendientes ajenos. Derivar de más lo
hace sentir que no trabajo. Varias veces lo que mandé al backend era arreglable en la app.

**Cómo aplicar:**
- Antes de escribir "esto es del backend", ABRIR el código y probar que la app no tiene el dato o la
  capacidad. Ejemplo real: dije que la app no podía filtrar la worklist por ciudad del preparador — falso:
  `/app/auth/me` ya devolvía `user.city` y el envío trae `origin_department`; solo había que cablearlo
  ([[business-rules-city-scope-lookup]]).
- Derivar SOLO lo que la app literalmente no puede hacer: datos que el backend no manda, publicar/scopear
  registros del servidor, credenciales externas (FCM/Firebase), lógica que vive en la base.
- Reportar primero LO QUE ARREGLÉ (con archivos), y recién después, corto, lo que queda del backend.
- El backend no re-invalida mis bugs diciendo "con el re-deploy ya está": verificar contra el deploy real
  antes de dar por cerrado, pero igual arreglar lo de la app ([[backend-audit-2026-11-12]]).

Ver [[feedback-working-style]], [[owner-decisions-are-final]].
