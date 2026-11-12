---
name: parallel-agents-method
description: El dueño quiere muchos agentes en paralelo; método que funcionó = carpetas disjuntas + contrato de rutas/tareas que el coordinador cablea al final.
metadata:
  node_type: memory
  type: feedback
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-11-12T08:45:25.811Z
---

El dueño pide repetidamente **agentes en paralelo** y "completar al 100%", no de a poco. El método que funcionó sin conflictos:

**How to apply:**
- Un agente = **una carpeta/feature disjunta** (`lib/features/<f>/` nueva, o archivos específicos no compartidos). Dos agentes nunca editan el mismo archivo.
- El **coordinador (yo)** construye primero la fundación compartida (pubspec, deps, `app.dart`, `main.dart`, AndroidManifest, core/*) y **prohíbe** a los agentes tocar: `lib/core/**`, `app.dart`, `main.dart`, `AndroidManifest.xml`, `lib/core/router/app_router.dart`, `lib/core/navigation/feature_tasks.dart`, `pubspec.yaml`.
- Cada agente expone `const List<RoleTask> <f>Tasks` + `final List<RouteBase> <f>Routes` en `presentation/<f>_routes.dart`; el coordinador los cablea al final en `app_router.dart` + `feature_tasks.dart` en una sola pasada.
- Solo UN agente corre `build_runner` por vez (si agrega tabla Drift); el resto no corre `build_runner` ni `pub get`.
- DoD por agente: `dart format lib/features/<f>; flutter analyze lib/features/<f>` → "No issues found!". El coordinador corre la verificación global (format+analyze+test) al final.
- Si la sesión se reinicia y quedan agentes a medias: NO reanudar a ciegas; evaluar el estado real (`flutter analyze`, revisar archivos), correr `build_runner` si alguien dejó una tabla Drift sin generar, y relanzar agentes frescos para lo incompleto.

**VERIFICAR la salida de CADA agente — no confiar (nov 2026).** Los agentes NO corren flutter (regla del
dueño + el skill `flutter-feature`); escriben código y el coordinador lo valida. Pasó dos veces: un agente
dejó un archivo con un **error de sintaxis** (llave de más + indentación) y OTRO se **colgó 20+ min** sin
terminar el widget ni los tests prometidos. Por eso: (1) el coordinador corre `getDiagnostics` sobre cada
archivo nuevo/tocado por el agente apenas cierra; (2) si el agente se cuelga, TaskStop y terminar la parte a
mano; (3) lo **interconectado** (mapa/GPS, pantallas que varios features comparten) lo hace el coordinador
mismo — repartirlo entre agentes da conflictos o archivos rotos. Un agente = archivos NUEVOS o un archivo
puntual no compartido; el coordinador cablea `driver_routes.dart`/`checklist_screen.dart`/home, etc.

**Variante que funcionó MUY bien en código EXISTENTE (nov 2026).** Para un cambio transversal (renombrar vocabulario en ~250 lugares) + varias mejoras a la vez, repartir **por ÁREA, no por tarea**: cada agente hace el cambio transversal **y** la mejora funcional **de su propia carpeta** (`features/store`, `features/carrier`, `features/driver`, `core` sin `core/api`), y el coordinador toma el resto (`features/picking`, `integration_test`) + el cableado. Así nadie toca el archivo de otro aunque las tareas se solapen conceptualmente. Reglas que hicieron la diferencia:
- Decirle a cada agente **qué NO tocar**, nombrando las carpetas de los otros y **siempre** `lib/core/api/**` (generado).
- Si un provider/firma compartida cambia, el coordinador deja un **alias de compatibilidad** (p. ej. mantener `ordersToPrepareProvider` derivado del nuevo notifier) para no romper archivos de otras áreas en pleno vuelo.
- **Agentes de solo lectura para auditar**: para relevar deuda/pedidos al backend, 3 agentes con `PROHIBIDO editar` dan informes accionables sin riesgo de conflicto.
- Pedirles que **reescriban la frase** cuando un reemplazo mecánico diría un absurdo; un agente detectó solo que "la cantidad de productos no es la cantidad de productos" no tenía sentido y acuñó "ítems" vs "productos etiquetados".
- Verificación del coordinador al cerrar cada agente: `getDiagnostics` → `dart format` → `flutter analyze` → tests **por área** y recién al final la suite completa.

**Why:** evita colisiones de last-writer-wins en archivos compartidos y mantiene el build siempre verde. Ver [[app-api-coverage-state]], [[test-battery-and-infra]].
