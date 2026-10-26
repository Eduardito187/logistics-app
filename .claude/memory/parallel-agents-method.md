---
name: parallel-agents-method
description: El dueño quiere muchos agentes en paralelo; método que funcionó = carpetas disjuntas + contrato de rutas/tareas que el coordinador cablea al final.
metadata:
  node_type: memory
  type: feedback
  originSessionId: 09382079-47de-4656-9b51-88ca4bb40fff
  modified: 2026-10-15T06:42:40.691Z
---

El dueño pide repetidamente **agentes en paralelo** y "completar al 100%", no de a poco. El método que funcionó sin conflictos:

**How to apply:**
- Un agente = **una carpeta/feature disjunta** (`lib/features/<f>/` nueva, o archivos específicos no compartidos). Dos agentes nunca editan el mismo archivo.
- El **coordinador (yo)** construye primero la fundación compartida (pubspec, deps, `app.dart`, `main.dart`, AndroidManifest, core/*) y **prohíbe** a los agentes tocar: `lib/core/**`, `app.dart`, `main.dart`, `AndroidManifest.xml`, `lib/core/router/app_router.dart`, `lib/core/navigation/feature_tasks.dart`, `pubspec.yaml`.
- Cada agente expone `const List<RoleTask> <f>Tasks` + `final List<RouteBase> <f>Routes` en `presentation/<f>_routes.dart`; el coordinador los cablea al final en `app_router.dart` + `feature_tasks.dart` en una sola pasada.
- Solo UN agente corre `build_runner` por vez (si agrega tabla Drift); el resto no corre `build_runner` ni `pub get`.
- DoD por agente: `dart format lib/features/<f>; flutter analyze lib/features/<f>` → "No issues found!". El coordinador corre la verificación global (format+analyze+test) al final.
- Si la sesión se reinicia y quedan agentes a medias: NO reanudar a ciegas; evaluar el estado real (`flutter analyze`, revisar archivos), correr `build_runner` si alguien dejó una tabla Drift sin generar, y relanzar agentes frescos para lo incompleto.

**Lecciones 2026-10-16 (9 agentes, roadmap de 19 puntos):**
- El coordinador instala TODAS las dependencias nuevas antes de lanzar (un `pub get` por agente rompe a los demás) y verifica que compilen importándolas en un test temporal (así apareció tarde el choque de `workmanager`).
- `main.dart`/`app.dart`/router los cablea el coordinador al final: cada agente devuelve "líneas exactas a agregar".
- Contratos entre agentes por **firma exacta** en el prompt (p. ej. `prefetchRouteTiles(...)`, `FailureReporter`), y el que consume compila contra ella al final.
- Builds/emulador: a lo sumo uno a la vez; `flutter test -j 2` si la PC está cargada; nunca `taskkill /IM dart.exe` (mata los tests de los otros). Un `flutter test` concurrente regenera `GeneratedPluginRegistrant` y puede romper una build release en curso.
- Al terminar: suite completa + e2e + build release, y recién ahí commits (ver skill github-pr-flow).

**Why:** evita colisiones de last-writer-wins en archivos compartidos y mantiene el build siempre verde. Ver [[app-api-coverage-state]].
