---
name: animated-app-icons
description: Agregar, redibujar o re-animar un ícono custom animado DisTrack de la app (AnimatedAppIcon / AppIcon) — SVG fuente, catálogo, generador, specs de animación, codemod Icons.* → AppIcon y tests. Usar cuando falte un ícono ("no hay ícono para…", "agrega un ícono de…"), cuando alguien escriba `Icon(Icons.x)`, cuando una animación se vea "básica", parcial o deforme, o al cambiar el motor `lib/core/icons/animated_app_icon.dart`.
---

# Íconos custom animados DisTrack — logistics-app

La app NO usa `Icons.*`: todo ícono es `AnimatedAppIcon(AppIcon.x, state: …)`. Brief original:
`docs/custom-animated-icons-brief.md`. Formato del SVG y reglas del motor: `tool/icons/README.md`
(leerlo antes de dibujar). Memoria: `.claude/memory/custom-animated-icons.md`.

## 🛑 Regla de ejecución

No correr Flutter, `dart`, Docker ni el backend salvo que el dueño lo pida en ese turno, y nunca desde
subagentes. Python sí (generador y codemod son scripts locales sin efectos de RAM). Al terminar, darle los
comandos de verificación (abajo), uno por bloque.

## Regla de diseño: el ícono COMPLETO se anima

Pedido explícito del dueño ("al 100%, todo el SVG, no solo una fracción"), igual que el panel web
(`logistics/docs/filament-iconos-custom-animados.md`). Al activar/tocar/éxito/error el motor ya hace las
4 cosas, y nada debe romperlo:
1. **Color + brillo** de TODAS las piezas hacia `highlightColor` (rojo de marca; Noche sobre un `Material`
   rojo; rojo oscuro si el ícono ya es rojo). Éxito → verde, error → ámbar + sacudida, loading → latido 35 %.
2. **Redibujo en cascada** de todas las piezas (rellenos escalan).
3. **Movimiento del conjunto** (`IconMotion`) + coreografía por pieza en los héroes.
4. **Pop del acento** (`ds-accent`, llega primero al color).

Apretar = se ilumina y se aprieta; soltar con < 12 px de movimiento = reproduce. Reduce motion = nada se
mueve. Nunca agregar una animación que mueva o coloree solo una pieza.

## Agregar un ícono nuevo

1. **¿Ya existe?** Buscar en `tool/icons/catalog.json` (95 íconos, campo `materials` = los `Icons.*` que
   reemplaza). Si un `Icons.x` ya está mapeado, usar ese `AppIcon`.
2. **Catálogo:** agregar una entrada
   `{"name": "<snake_case>", "materials": ["<icon_material>", …], "label": "<etiqueta en español>", "lot": "nav|role|state|util", "hero": false, "ref": "<svg web de referencia>"}`.
   El `label` es lo que anuncia el lector de pantalla.
3. **Dibujo:** `tool/icons/svg/<name>.svg` — grilla 24, trazo 2.2, dentro de 2.5..21.5, separación ≥ 2.4,
   2–7 formas ordenadas de estructura a detalle, exactamente UNA `class="ds-accent"`, tags `ds-p-*` para
   coreografía/loops. Estilo: copiar el lenguaje de `tool/icons/reference-web/` (mismo set de marca).
   Prohibido `<g transform>`, `<style>`, `<text>`, ids, URLs.
4. **Generar:** `python tool/icons/gen_icons.py` (requiere `pip install svgelements`) → reescribe
   `lib/core/icons/generated/app_icon.g.dart` y `app_icon_glyphs.g.dart`. No editarlos a mano.
5. **Animación:** entrada en el `*_specs.dart` de su lote (`lib/core/icons/specs/`), p. ej.
   `AppIcon.x: AppIconSpec(motion: IconMotion.nudgeRight, loop: IconLoop.pulse, duration: Duration(milliseconds: 420))`.
   - `IconMotion`: spin, pulse, bounce, pop, wiggle, nudgeRight/Left/Up/Down, swing, blink, draw, stagger, fillUp.
   - `IconLoop` (solo estados reales): spin, pulse, sweep (escaneo), locate (GPS, `ds-p-ring`), print (`ds-p-paper`), breathe, blink.
   - 200–500 ms (héroes hasta ~900); movimiento claro y lento (usuarios mayores), sin rebotes exagerados.
   - Coreografía opcional `PartPose? f(GlyphPart part, int i, double t)` con `part.has('<tag>')` y los
     helpers `hump`, `segment`, `easeOut`, `easeInOut`, `popScale`, `damped`.
   - El test de catálogo falla si un `AppIcon` no tiene spec (`AppIconSpec.fallback`).
6. **Usar:** `AnimatedAppIcon(AppIcon.x, state: …)`; si ya había `Icon(Icons.x)`, correr el codemod:
   `python3 tool/icons/migrate_icons.py lib/features/<f>` (conserva CRLF/LF, agrega el import una vez).
   Revisar a mano los `IconData` pasados como parámetro (el codemod solo toca `Icon(Icons.x…)`).

## Estados (qué pasar en `state:`)

| Situación | Estado |
| --- | --- |
| Pestaña/ítem seleccionado | `active` |
| Escaneando, sincronizando, imprimiendo, buscando GPS | `loading` (loop real) |
| Resultado OK / pastilla de resultado (`StatusPill.iconState`) | `success` |
| Falla / rechazo | `error` |
| Resto | `idle` (por defecto) |

Otros parámetros: `size`, `color`, `accentColor`, `highlightColor`, `semanticLabel`,
`excludeFromSemantics` (si el texto vecino ya lo dice), `ambient` (solo el botón central: respira 3 ciclos),
`animateOnMount`.

## Cambiar el motor (`animated_app_icon.dart`)

- Cuatro controladores: `_action` (activar/tocar), `_loop`, `_press`, `_fill`. El brillo `lit` =
  máx(press, envolvente de activar/éxito, joroba de error, 0.35·joroba en loading).
- Usar `Matrix4.translationValues` (`Matrix4.translate` con `int` rompe en vector_math 2.1) y `1.0`
  (no `1`) en `math.min/max` que alimentan `Color.lerp`.
- Ningún loop infinito fuera de `loading` (rompe `pumpAndSettle` en cientos de tests).
- Mantener el test `test/icons/animated_app_icon_test.dart` alineado (catálogo, estados, reduce motion,
  toque, semántica, botón rojo).

## Tests

- Encontrar íconos con `findAppIcon(AppIcon.x)` / `findAppIconInState(AppIcon.x, AppIconState.y)`
  (`test/support/app_icon_finders.dart`); nunca `find.byIcon`.
- Pantalla con un ícono en `loading`: `pump(Duration)` en vez de `pumpAndSettle`.

## Verificación (la corre el dueño, de a uno)

```bash
python tool/icons/gen_icons.py
```
```bash
dart format lib test
```
```bash
flutter analyze
```
```bash
flutter test test/icons
```
```bash
flutter test
```

Si no se corrieron, decirlo: "cambios sin compilar".
