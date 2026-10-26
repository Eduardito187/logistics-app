---
name: git-communication-rule
description: "Regla firme del dueño: NUNCA commitear/pushear sin que lo pida en ese turno; siempre avisar toda acción de git con el hash."
metadata:
  node_type: memory
  type: feedback
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-22T02:31:51.213Z
---

El dueño se molestó al descubrir commits que no había pedido ("en todo el día no te he pedido ningún commit, ¿hiciste algún commit hoy?" / "no soy adivino, tiene que haber comunicación"). Regla firme:

- **No hacer `git commit` ni `git push` sin que el usuario lo pida EXPLÍCITAMENTE en ese mismo turno.** Un OK anterior no vale para los cambios siguientes. (Coincide con la regla 2 de CLAUDE.md.)
- **Comunicar siempre toda acción de git de forma clara, con el hash corto**, apenas se hace. Nunca dejar un commit/push "silencioso".
- Si hace falta una rama/commit para avanzar, **preguntar primero**; no asumir.
- Todo el trabajo queda **sin commitear** hasta que el dueño dé la orden; está acostumbrado a revisar y decidir él cuándo se versiona.

**Why:** perdió confianza por commits no comunicados; valora el control y la comunicación explícita sobre git.
**How to apply:** trabajar con el árbol sucio sin problema; al terminar, ofrecer commitear y esperar el OK. Para el flujo de ramas/PR ver [[portable-memory-skills]] y el skill `github-pr-flow`.
