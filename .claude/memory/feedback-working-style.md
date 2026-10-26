---
name: feedback-working-style
description: Cómo quiere el dueño que trabaje: agentes en paralelo, cerrar al 100%, decisiones propias, pedidos al backend por doc, sin preguntar de más
metadata:
  type: feedback
---

- **Agentes en paralelo y "concluir al 100%":** cuando pide algo grande quiere que se reparta en agentes simultáneos y se termine todo, no por partes. Ver [[parallel-agents-method]].
- **Decidir sin preguntar de más:** "tomá las decisiones que sean necesarias". Decidir con criterio, dejarlas explícitas en el reporte (para que pueda revertir) y preguntar solo lo irreversible o que es suyo (credenciales, cuentas, publicar).
- **Lo que falte del backend:** documentarlo en `docs/backend-requests/` y, si hay sesión del backend activa, mandárselo; él lo pasa al agente del backend y trae la respuesta.
- **Reportar con números** (tests, tamaños, analyze) y ser honesto con lo no verificado (hardware real, push sin credenciales).
- **No inventar valores** de URLs/credenciales: dejar claves vacías y avisar.
- Cuando corrige algo ("te dije eliminar eso por completo"), hacerlo exhaustivo (grep de todo el repo + memorias) y verificar con números.

**Why:** lo pidió repetidamente a lo largo de la sesión del 2026-10-16 y validó los resultados así entregados.
**How to apply:** en tareas grandes planificar reparto por carpetas, instalar dependencias primero, integrar y verificar al final; en el reporte, decisiones tomadas + pendientes que son suyos.
