# Íconos custom animados DisTrack (app)

Fuente de verdad de los íconos de la app. Brief completo: `docs/custom-animated-icons-brief.md`.

```
tool/icons/catalog.json      cada AppIcon: nombre, Icons.* que reemplaza, etiqueta (es), lote
tool/icons/svg/<name>.svg    dibujo de cada AppIcon (este README define el formato)
tool/icons/reference-web/    set DisTrack del panel web (misma marca): referencia de estilo
tool/icons/gen_icons.py      genera lib/core/icons/generated/*.g.dart
lib/core/icons/specs/*.dart  animación de cada ícono (motion, loop, coreografía por pieza)
```

Regenerar tras tocar un SVG o el catálogo:

```bash
pip install svgelements
python tool/icons/gen_icons.py
```

## Formato del SVG (obligatorio)

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor"
     stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="…"/>
  <path class="ds-accent" d="…"/>          <!-- 1 pieza clave del significado -->
  <circle class="ds-p-ring" …/>             <!-- piezas con etiqueta de coreografía -->
  <circle cx="…" cy="…" r="1.2" fill="currentColor" stroke="none"/>   <!-- punto relleno -->
</svg>
```

- **Grilla 24×24, trazo 2.2** (≈2.2 dp a 24 dp): el motor dibuja SIEMPRE con 2.2, así que el
  SVG debe verse bien con ese grosor. Separación mínima entre trazos paralelos: **2.4** (si no,
  se pegan). Dibujo dentro de 2.5..21.5. Puntas y uniones redondeadas.
- **Formas permitidas:** `path`, `circle`, `ellipse`, `rect` (puede tener `rx`), `line`,
  `polyline`, `polygon`. Nada de `<g>` con transform, `<text>`, `<style>`, `<image>`, ids, ni URLs.
- **Cada forma = una pieza animable** (se redibuja en cascada en el orden del archivo): ordenar
  de la estructura principal a los detalles. Ideal 2–7 piezas.
- **`class="ds-accent"`** en exactamente UNA forma: la clave del significado (el check, la punta de
  la flecha, la gota, el punto del pin…). Remata la animación con un pop.
- **Rellenos:** `fill="currentColor" stroke="none"` para puntos/sólidos chicos (aparecen escalando).
- **Etiquetas de coreografía** `class="ds-p-<tag>"` (se pueden combinar con ds-accent):
  - `ds-p-fill`: la forma se rellena (tinte) cuando el ícono está **activo** (outlined→filled).
  - `ds-p-spin`: gira en el loop `spin` (las flechas dentro de una nube, el engranaje).
  - `ds-p-ring`: se expande y desvanece en el loop `locate` (anillo de GPS).
  - `ds-p-paper`: se desliza en el loop `print` (hoja que sale de la impresora).
  - Cualquier otra (`ds-p-box`, `ds-p-truck`, `ds-p-laser`…) para que la coreografía la identifique.
- **Legible a 24 dp y a 28–32 dp**, a un color, en claro y oscuro. Reconocible en cualquier frame.
- **Estilo DisTrack:** geométrico, industrial (andén, cajas, señalética), esquinas casi rectas
  (`rx` ≤ 2), nada de detalles menores a 1.5. Mismo concepto que el `Icons.*` que reemplaza, pero
  dibujado nuevo con identidad de marca (usar `reference-web/` como guía de estilo).

## Qué hace el motor con TODO ícono (no solo una parte)

Al activarse, al tocarlo o en éxito/error, el ícono COMPLETO se anima, igual que en el panel web:

1. **Color + brillo:** todas las piezas pasan al color de resalte (`highlightColor`, rojo de marca por
   defecto; Noche si el ícono está sobre un botón rojo; un rojo más oscuro si el ícono ya es rojo) con
   un brillo suave detrás de cada trazo. Éxito resalta en verde y error en ámbar (con sacudida).
2. **Trazo:** TODAS las piezas se redibujan en cascada (los rellenos aparecen escalando).
3. **Movimiento:** el conjunto hace su `motion` y los héroes, su coreografía por pieza.
4. **Remate:** la pieza `ds-accent` llega primero al color y hace un pop.

Al apoyar el dedo, el ícono entero se ilumina y se aprieta; al soltar (si fue un toque, no un scroll)
reproduce la animación completa. En `loading` el ícono entero late suave hacia el resalte además de su
loop. Con reduce motion, nada se mueve.

## Animación (`lib/core/icons/specs/<lote>_specs.dart`)

```dart
final Map<AppIcon, AppIconSpec> kRoleIconSpecs = {
  AppIcon.deliver: AppIconSpec(
    motion: IconMotion.nudgeRight,          // movimiento del conjunto al activarse/tocar
    loop: IconLoop.pulse,                   // loop en loading
    duration: Duration(milliseconds: 820),  // 200–500 ms; héroes hasta ~900
    choreography: _deliver,                 // (opcional) pose por pieza, t ya en 0..1
  ),
};

PartPose? _deliver(GlyphPart part, int i, double t) {
  if (part.has('box')) return PartPose(dy: -6 * (1 - easeOut(segment(t, .35, .8))));
  return null;
}
```

Helpers en `icon_motion.dart`: `hump`, `segment`, `easeOut`, `easeInOut`, `popScale`, `damped`.
Reglas: movimiento claro y lento (personas mayores), sin rebotes exagerados; reconocible en cualquier
frame; loops solo para estados reales (scan, sync, print, GPS). El rojo `#E30613` NO se usa porque sí:
el acento toma `accentColor` solo si el llamador lo pasa.
