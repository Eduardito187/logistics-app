---
name: custom-animated-icons
description: "Íconos custom animados DisTrack (oct 2026): AnimatedAppIcon reemplaza a Icons.* en toda la app; dónde está cada pieza y cómo agregar un ícono"
metadata:
  type: project
  modified: 2026-10-26T00:00:00.000Z
---

La app ya no usa `Icon(Icons.x)`: todo ícono es `AnimatedAppIcon(AppIcon.x, state: …)` (brief: `docs/custom-animated-icons-brief.md`). Hecho el 2026-10-26 con agentes en paralelo (dibujo por lotes + cableado por feature).

**Decisión:** todo en Flutter puro (CustomPainter), sin Rive (un `.riv` solo se crea con el editor de Rive) ni Lottie. El motor hace de "state machine": estados `idle/active/pressed/loading/success/error`, dibujo progresivo en cascada, movimiento propio por ícono, coreografía por pieza para los héroes, loops cortables, reduce motion y semántica en español. 0 KB de assets.

**Dónde está cada cosa:**
- `tool/icons/catalog.json`: 95 `AppIcon` ↔ 153 `Icons.*` que reemplazan + etiqueta + lote. `tool/icons/svg/<name>.svg`: dibujo fuente (formato y reglas en `tool/icons/README.md`: grilla 24, trazo 2.2, un `ds-accent`, tags `ds-p-*`). `tool/icons/reference-web/`: set del panel web como guía de estilo.
- `python tool/icons/gen_icons.py` (necesita `pip install svgelements`) → `lib/core/icons/generated/app_icon.g.dart` (enum) y `app_icon_glyphs.g.dart` (formas). Luego `dart format lib/core/icons/generated`.
- `lib/core/icons/specs/*_specs.dart`: animación de cada ícono (motion, loop, duración, coreografía). `animated_app_icon.dart`: motor.
- `python3 tool/icons/migrate_icons.py <rutas>`: codemod `Icon(Icons.x)` → `AnimatedAppIcon(AppIcon.y)` (conserva CRLF/LF).
- Tests: `test/icons/` (motor) y `test/support/app_icon_finders.dart` (`findAppIcon`, `findAppIconInState` en vez de `find.byIcon`).

**Animación del ícono COMPLETO (pedido explícito del dueño, igual que la web):** al activar/tocar/éxito/error, TODAS las piezas cambian al color de resalte con brillo, TODOS los trazos se redibujan, el conjunto se mueve y el acento remata. Nunca volver a animar o colorear solo una pieza ("solo una fracción" fue la queja). `highlightColor` por defecto: rojo de marca; Noche sobre botones rojos (detecta el `Material` de fondo); rojo oscuro si el ícono ya es rojo. Éxito resalta en verde (`AppColors.success`), error en ámbar con sacudida, `loading` late suave (35 %) hacia el resalte. Al apoyar el dedo se ilumina y aprieta; al soltar reproduce la animación solo si el dedo se movió < 12 px (un scroll no la dispara).

**Estado (2026-10-26):** migración completa por revisión estática (164 archivos usan `AppIcon`; no quedan `Icons.*` salvo los fallbacks del enum generado y de `NavTab`/`RoleTask`). La última versión del motor (resalte completo, detección de fondo rojo, `StatusPill.iconState`, respiración de 3 ciclos) **NO se compiló ni testeó**: la verifica el dueño con `dart format lib test`, `flutter analyze`, `flutter test test/icons` y `flutter test`, uno por vez. Riesgos marcados por los agentes: `live_gps_screen_test` (usa `pump` por el loop de GPS) y tests de sync/transportista que cuentan pumps.

**Gotchas:**
- `NavTab` y `RoleTask` conservan `icon` (IconData) como fallback Material (brief §6) + `appIcon`. `EmptyState/StatTile/StatusPill.icon` y `UserRole.icon` son `AppIcon`. `StatusPill.iconState` anima pastillas de resultado.
- Un ícono en `loading` es un loop real: un test que lo deje así no asienta con `pumpAndSettle` (usar `pump`). El botón central (`ambient`) respira solo 3 ciclos y queda quieto.
- `Matrix4.translate` de vector_math 2.1 rompe con `int` → el motor usa `Matrix4.translationValues`.
- El repo mezcla CRLF y LF por archivo: cualquier script que reescriba archivos debe conservar el fin de línea (si no, el diff muestra el archivo entero).
- NUNCA correr Flutter en paralelo desde agentes (colgó WSL, ver [[wsl-gradle-memory-hang]]). El dueño verifica él mismo.

Ver [[distrack-rebrand]], [[parallel-agents-method]].
