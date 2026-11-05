import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_icon_specs.dart';
import 'app_icon_state.dart';
import 'generated/app_icon.g.dart';
import 'generated/app_icon_glyphs.g.dart';
import 'icon_glyph.dart';
import 'icon_motion.dart';

/// Ícono animado custom de DisTrack. Reemplaza a `Icon(Icons.x)` en toda la
/// app: el resto del código solo pide un [AppIcon] y un [AppIconState].
///
/// - **Color y tamaño** se heredan del [IconTheme] (igual que [Icon]): funciona
///   dentro de `IconButton`, `ListTile`, chips y botones sin tocar nada más.
/// - **Estados** ([AppIconState]): cada cambio anima el ícono COMPLETO, no una
///   parte: TODOS los trazos se redibujan en cascada, el ícono entero pasa al
///   color de resalte ([highlightColor], rojo de marca por defecto) con un
///   brillo suave, el conjunto hace su movimiento propio, las piezas de los
///   íconos héroe ejecutan su coreografía y el acento remata con un pop.
///   Éxito resalta en verde; error sacude y resalta en ámbar.
/// - **Toque**: mientras el dedo está encima, todo el ícono se aprieta (0.9) y
///   se ilumina; al soltar, reproduce su animación completa.
/// - **Reduce motion**: con `MediaQuery.disableAnimations` muestra directamente
///   el estado final, sin animar.
/// - **Semántica**: siempre anuncia [semanticLabel] (por defecto la etiqueta en
///   español del catálogo), salvo [excludeFromSemantics].
///
/// Los dibujos salen de `tool/icons/svg/` (generados a
/// `generated/app_icon_glyphs.g.dart`); las animaciones, de `specs/*.dart`.
class AnimatedAppIcon extends StatefulWidget {
  const AnimatedAppIcon(
    this.icon, {
    this.state = AppIconState.idle,
    this.size,
    this.color,
    this.accentColor,
    this.highlightColor,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.ambient = false,
    this.animateOnMount = false,
    super.key,
  });

  final AppIcon icon;
  final AppIconState state;

  /// Lado en dp. `null` = [IconTheme] (24 por defecto).
  final double? size;

  /// Color del trazo. `null` = [IconTheme] del contexto.
  final Color? color;

  /// Color del acento (la pieza clave) cuando el ícono está activo o en éxito.
  /// `null` = mismo [color] (rojo neutralizado: el acento no se pinta solo).
  final Color? accentColor;

  /// Color al que pasa el ícono COMPLETO (con brillo) mientras se toca o se
  /// anima. `null` = [accentColor] o el rojo de marca (blanco si el ícono ya
  /// es rojo, p. ej. sobre el botón central).
  final Color? highlightColor;

  /// Etiqueta en español para lectores de pantalla. `null` = [AppIcon.label].
  final String? semanticLabel;

  /// Para íconos decorativos dentro de un control que ya tiene su etiqueta.
  final bool excludeFromSemantics;

  /// Respiración sutil en reposo (solo el botón central de la barra).
  final bool ambient;

  /// Reproduce la activación al aparecer (p. ej. una tarjeta recién mostrada).
  final bool animateOnMount;

  @override
  State<AnimatedAppIcon> createState() => _AnimatedAppIconState();
}

/// Qué animación de una sola vez está corriendo.
enum _Shot { activate, success, error }

class _AnimatedAppIconState extends State<AnimatedAppIcon>
    with TickerProviderStateMixin {
  late final AnimationController _action;
  late final AnimationController _loop;
  late final AnimationController _press;
  late final AnimationController _fill;
  late final Listenable _repaint;
  _Shot _shot = _Shot.activate;
  bool _reduce = false;
  bool _mounted = false;

  AppIconSpec get _spec => appIconSpecFor(widget.icon);

  @override
  void initState() {
    super.initState();
    _action = AnimationController(vsync: this, duration: _spec.duration);
    _loop = AnimationController(vsync: this);
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.state == AppIconState.active ? 1 : 0,
    );
    _action.value = 1; // en reposo: dibujo completo.
    _loop.addStatusListener(_onLoopStatus);
    _repaint = Listenable.merge([_action, _loop, _press, _fill]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_mounted) {
      _mounted = true;
      _enter(null, widget.state, onMount: true);
    } else if (_reduce) {
      _settle();
    }
  }

  @override
  void didUpdateWidget(AnimatedAppIcon old) {
    super.didUpdateWidget(old);
    if (old.icon != widget.icon) {
      _action.duration = _spec.duration;
      _loop.stop();
      _loop.value = 0;
      _enter(null, widget.state, onMount: true);
      return;
    }
    if (old.state != widget.state || old.ambient != widget.ambient) {
      _enter(old.state, widget.state);
    }
  }

  /// Aplica la transición de estado [from] → [to].
  void _enter(AppIconState? from, AppIconState to, {bool onMount = false}) {
    // Loops: solo en loading (o respiración ambiente en reposo). Se cortan al instante.
    final wantsLoop =
        to == AppIconState.loading ||
        (widget.ambient &&
            (to == AppIconState.idle || to == AppIconState.active));
    if (!wantsLoop || _reduce) {
      _loop.stop();
      _loop.value = 0;
    } else if (to == AppIconState.loading) {
      // Loading: loop real mientras dure el estado (escaneo, sync, impresión…).
      _breaths = 0;
      _loop.duration = _loopDuration(_spec.loop);
      _loop.repeat();
    } else if (from == null || from == AppIconState.loading || from != to) {
      // Respiración del botón central: unas pocas veces al quedar en reposo y
      // después quieto (invita al toque sin gastar batería en gama baja ni
      // dejar animaciones infinitas que cuelguen `pumpAndSettle`).
      _breaths = 0;
      _loop.duration = const Duration(milliseconds: 2500);
      _loop.forward(from: 0);
    }

    // Relleno de "activo".
    final fillTarget = to == AppIconState.active ? 1.0 : 0.0;
    if (_reduce || onMount) {
      _fill.value = fillTarget;
    } else {
      _fill.animateTo(fillTarget, curve: Curves.easeOutCubic);
    }

    // Toque explícito.
    if (to == AppIconState.pressed) {
      _reduce ? _press.value = 1 : _press.forward();
    } else if (from == AppIconState.pressed) {
      _reduce ? _press.value = 0 : _press.reverse();
    }

    // Animaciones de una sola vez.
    switch (to) {
      case AppIconState.active
          when from != AppIconState.pressed &&
              (!onMount || widget.animateOnMount):
        _play(_Shot.activate);
      case AppIconState.success when from != AppIconState.success:
        _play(_Shot.success);
      case AppIconState.error when from != AppIconState.error:
        _play(_Shot.error);
      case AppIconState.idle when onMount && widget.animateOnMount:
        _play(_Shot.activate);
      default:
        break;
    }
  }

  /// Ciclos de respiración que hace el botón central antes de quedarse quieto.
  static const int _kBreathCycles = 3;
  int _breaths = 0;

  void _onLoopStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        widget.state == AppIconState.loading) {
      return;
    }
    _breaths++;
    if (_breaths < _kBreathCycles) {
      _loop.forward(from: 0);
    } else {
      _loop.value = 0;
    }
  }

  void _play(_Shot shot) {
    _shot = shot;
    if (_reduce) {
      _action.value = 1;
      return;
    }
    _action.duration = switch (shot) {
      _Shot.activate => _spec.duration,
      _Shot.success => const Duration(milliseconds: 500),
      _Shot.error => const Duration(milliseconds: 360),
    };
    _action.forward(from: 0);
  }

  void _settle() {
    _action.value = 1;
    _loop.stop();
    _loop.value = 0;
    _press.value = widget.state == AppIconState.pressed ? 1 : 0;
    _fill.value = widget.state == AppIconState.active ? 1 : 0;
  }

  Duration _loopDuration(IconLoop loop) => switch (loop) {
    IconLoop.spin => const Duration(milliseconds: 1100),
    IconLoop.pulse => const Duration(milliseconds: 1200),
    IconLoop.sweep => const Duration(milliseconds: 1400),
    IconLoop.locate => const Duration(milliseconds: 1600),
    IconLoop.print => const Duration(milliseconds: 1200),
    IconLoop.breathe => const Duration(milliseconds: 2500),
    IconLoop.blink => const Duration(milliseconds: 1000),
  };

  @override
  void dispose() {
    _action.dispose();
    _loop.dispose();
    _press.dispose();
    _fill.dispose();
    super.dispose();
  }

  Offset? _downAt;

  void _down(PointerDownEvent event) {
    _downAt = event.position;
    if (!_reduce && widget.state != AppIconState.pressed) _press.forward();
  }

  void _up(PointerEvent event) {
    if (widget.state == AppIconState.pressed) return;
    _reduce ? _press.value = 0 : _press.reverse();
    // Un toque (no un arrastre de scroll) "ejecuta" la animación completa.
    final moved = _downAt == null
        ? double.infinity
        : (event.position - _downAt!).distance;
    _downAt = null;
    if (event is PointerUpEvent &&
        moved < 12 &&
        !_reduce &&
        widget.state != AppIconState.loading) {
      _play(_Shot.activate);
    }
  }

  /// Resalte por defecto: rojo de marca, salvo que el ícono esté sobre un
  /// fondo rojo (un botón relleno de marca), donde el rojo lo haría
  /// desaparecer: ahí resalta en Noche.
  static Color _highlightFor(Color base, Color? background) {
    if (background != null &&
        background.a > 0.5 &&
        _distance(background, AppColors.brand) < 0.35) {
      return AppColors.nightBg;
    }
    return _contrasting(base, AppColors.brand);
  }

  static double _distance(Color a, Color b) =>
      (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();

  /// [preferred] salvo que el ícono ya sea de ese color (p. ej. una pestaña
  /// activa en rojo): ahí el resalte es una versión más oscura del mismo color
  /// para que el cambio se note sin perderse sobre el fondo.
  static Color _contrasting(Color base, Color preferred) {
    if (_distance(base, preferred) > 0.35) return preferred;
    return Color.lerp(preferred, Colors.black, 0.35)!;
  }

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = widget.size ?? iconTheme.size ?? 24;
    final base =
        widget.color ??
        iconTheme.color ??
        Theme.of(context).colorScheme.onSurface;
    final opacity = iconTheme.opacity ?? 1;
    final glyph = kAppIconGlyphs[widget.icon];

    Widget child;
    if (glyph == null) {
      // Fallback: mientras un dibujo no exista, se ve el Material equivalente.
      child = Icon(widget.icon.fallback, size: size, color: base);
    } else {
      child = RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _AppIconPainter(
            glyph: glyph,
            spec: _spec,
            repaint: _repaint,
            frame: () => _Frame(
              shot: _shot,
              t: _action.value,
              running: _action.isAnimating || _action.value < 1,
              loopT: _loop.value,
              looping: _loop.isAnimating,
              breathing: widget.ambient && widget.state != AppIconState.loading,
              press: _press.value,
              fill: _fill.value,
              state: widget.state,
            ),
            color: base.withValues(alpha: base.a * opacity),
            accentColor: widget.accentColor,
            highlight:
                widget.highlightColor ??
                widget.accentColor ??
                _highlightFor(base, Material.maybeOf(context)?.color),
            successHighlight: _contrasting(base, AppColors.success),
          ),
        ),
      );
      child = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: child,
      );
    }

    if (widget.excludeFromSemantics) {
      return ExcludeSemantics(child: child);
    }
    return Semantics(
      label: widget.semanticLabel ?? widget.icon.label,
      image: true,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// Foto del estado de las animaciones en un frame.
class _Frame {
  const _Frame({
    required this.shot,
    required this.t,
    required this.running,
    required this.loopT,
    required this.looping,
    required this.breathing,
    required this.press,
    required this.fill,
    required this.state,
  });

  final _Shot shot;
  final double t;
  final bool running;
  final double loopT;
  final bool looping;
  final bool breathing;
  final double press;
  final double fill;
  final AppIconState state;
}

class _AppIconPainter extends CustomPainter {
  _AppIconPainter({
    required this.glyph,
    required this.spec,
    required this.frame,
    required this.color,
    required this.accentColor,
    required this.highlight,
    required this.successHighlight,
    required Listenable repaint,
  }) : super(repaint: repaint);

  /// Grosor del trazo en la grilla de 24 (≈2.2 dp a 24 dp, brief §1).
  static const double stroke = 2.2;

  final IconGlyph glyph;
  final AppIconSpec spec;
  final _Frame Function() frame;
  final Color color;
  final Color? accentColor;

  /// Color al que pasa el ícono COMPLETO mientras se toca o se anima.
  final Color highlight;

  /// Color de resalte del estado de éxito.
  final Color successHighlight;

  /// Resalte durante una animación de una sola vez: sube rápido, se sostiene
  /// mientras el trazo se redibuja y vuelve al color normal al terminar.
  static double _envelope(double t) {
    if (t < 0.15) return t / 0.15;
    if (t < 0.7) return 1;
    return 1 - (t - 0.7) / 0.3;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame();
    final scale = size.shortestSide / 24;
    final t = f.running ? f.t : 1.0;

    canvas.save();
    canvas.scale(scale);

    // ---- Transformación del ícono completo ----
    var opacity = 1.0;
    final m = Matrix4.identity();
    void around(double cx, double cy, Matrix4 inner) {
      m
        ..multiply(Matrix4.translationValues(cx, cy, 0))
        ..multiply(inner)
        ..multiply(Matrix4.translationValues(-cx, -cy, 0));
    }

    // Toque: se aprieta.
    if (f.press > 0) {
      final s = 1 - 0.1 * f.press;
      around(12, 12, Matrix4.diagonal3Values(s, s, 1));
      opacity *= 1 - 0.1 * f.press;
    }

    // Loop del conjunto.
    if (f.looping) {
      if (f.breathing) {
        final s = 1 + 0.02 * hump(f.loopT);
        around(12, 12, Matrix4.diagonal3Values(s, s, 1));
      } else {
        switch (spec.loop) {
          case IconLoop.spin when !glyph.parts.any((p) => p.has('spin')):
            around(12, 12, Matrix4.rotationZ(f.loopT * 2 * math.pi));
          case IconLoop.pulse:
            final s = 1 + 0.08 * hump(f.loopT);
            around(12, 12, Matrix4.diagonal3Values(s, s, 1));
          case IconLoop.blink:
            opacity *= 0.55 + 0.45 * (1 - hump(f.loopT));
          default:
            break;
        }
      }
    }

    // Movimiento de una sola vez + resaltado del ícono COMPLETO (como la web):
    // mientras se toca o se ejecuta, todo el ícono pasa al color de resalte con
    // un brillo suave, no solo una pieza.
    var paintColor = color;
    var glowColor = highlight;
    var lit = f.press; // 0..1: cuánto está resaltado el ícono entero.
    if (f.running) {
      switch (f.shot) {
        case _Shot.error:
          // Sacudida ±3 dp + pulso ámbar de todo el ícono.
          _translate(m, 3 * damped(t, cycles: 2.5), 0);
          glowColor = AppColors.warning;
          lit = math.max(lit, hump(t));
        case _Shot.success:
          final s = popScale(t, peak: 1.15);
          around(12, 12, Matrix4.diagonal3Values(s, s, 1));
          glowColor = successHighlight;
          lit = math.max(lit, _envelope(t));
        case _Shot.activate:
          _applyMotion(spec.motion, t, around, m);
          lit = math.max(lit, _envelope(t));
      }
    }
    // En loading el ícono entero late suavemente hacia el resalte (sutil:
    // offline-invisible, no debe parecer que hay que esperar).
    if (f.looping && !f.breathing) lit = math.max(lit, 0.35 * hump(f.loopT));
    if (lit > 0) paintColor = Color.lerp(color, glowColor, lit)!;
    canvas.transform(m.storage);

    // ---- Piezas ----
    final parts = glyph.parts;
    final n = parts.length;
    final stagger = n > 1 ? math.min(0.08, 0.45 / (n - 1)) : 0.0;
    final poser = f.shot == _Shot.success
        ? (spec.successChoreography ?? spec.choreography)
        : spec.choreography;

    for (var i = 0; i < n; i++) {
      final part = parts[i];
      final bounds = glyphBounds(part);
      final c = bounds.center;

      // Pose de coreografía (héroes) mientras corre la activación/éxito.
      final pose = (f.running && f.shot != _Shot.error && poser != null)
          ? (poser(part, i, t) ?? PartPose.identity)
          : PartPose.identity;

      // Dibujo progresivo en cascada.
      var draw = 1.0;
      if (f.running && f.shot != _Shot.error && spec.drawOn) {
        draw = segment(t, i * stagger, i * stagger + 0.55);
      }
      if (pose.draw != null) draw = pose.draw!;

      var partScale = pose.scale;
      var partRot = pose.rotation;
      var dy = pose.dy;
      var partOpacity = part.opacity * pose.opacity * opacity;

      // Pop escalonado (grillas/tableros).
      if (f.running &&
          f.shot == _Shot.activate &&
          spec.motion == IconMotion.stagger) {
        partScale *= popScale(segment(t, i * 0.1, i * 0.1 + 0.6), peak: 1.2);
      }
      // Remate: el acento hace pop al final.
      if (f.running && part.accent && f.shot != _Shot.error) {
        partScale *= popScale(segment(t, 0.5, 1), peak: 1.3);
      }

      // Loops por pieza.
      if (f.looping && !f.breathing) {
        switch (spec.loop) {
          case IconLoop.spin when part.has('spin'):
            partRot += f.loopT * 2 * math.pi;
          case IconLoop.locate when part.has('ring'):
            partScale *= 1 + 0.45 * f.loopT;
            partOpacity *= 1 - f.loopT;
          case IconLoop.print when part.has('paper'):
            dy += 3 * hump(f.loopT);
          default:
            break;
        }
      }

      if (partOpacity <= 0.001) continue;

      canvas.save();
      canvas.translate(c.dx + pose.dx, c.dy + dy);
      if (partRot != 0) canvas.rotate(partRot);
      if (partScale != 1) canvas.scale(partScale);
      canvas.translate(-c.dx, -c.dy);

      var partColor =
          (part.accent &&
              accentColor != null &&
              (f.state == AppIconState.active ||
                  f.state == AppIconState.success))
          ? accentColor!
          : paintColor;
      // La pieza clave llega antes al color de resalte (remata la animación).
      if (part.accent && lit > 0) {
        partColor = Color.lerp(partColor, glowColor, math.min(1.0, lit * 1.5))!;
      }
      final paint = Paint()
        ..isAntiAlias = true
        ..color = partColor.withValues(alpha: partColor.a * partOpacity);
      // Brillo suave detrás de CADA pieza mientras el ícono está resaltado.
      final glow = lit > 0.02
          ? (Paint()
              ..isAntiAlias = true
              ..color = glowColor.withValues(
                alpha: glowColor.a * partOpacity * 0.45 * lit,
              )
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4))
          : null;

      if (part.fill) {
        // Los rellenos aparecen escalando junto con el dibujo progresivo.
        if (draw < 1) {
          canvas.translate(c.dx, c.dy);
          canvas.scale(easeOut(draw));
          canvas.translate(-c.dx, -c.dy);
        }
        if (glow != null) {
          canvas.drawPath(glyphPath(part), glow..style = PaintingStyle.fill);
        }
        canvas.drawPath(glyphPath(part), paint..style = PaintingStyle.fill);
      } else {
        // Relleno de "activo" (outlined → filled), con la metáfora fillUp.
        if (f.fill > 0 && part.has('fill')) {
          final tint = Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill
            ..color = partColor.withValues(
              alpha: partColor.a * partOpacity * 0.28 * f.fill,
            );
          if (spec.motion == IconMotion.fillUp && f.fill < 1) {
            canvas.save();
            canvas.clipRect(
              Rect.fromLTRB(
                bounds.left - 2,
                bounds.bottom - bounds.height * f.fill,
                bounds.right + 2,
                bounds.bottom + 2,
              ),
            );
            canvas.drawPath(glyphPath(part), tint);
            canvas.restore();
          } else {
            canvas.drawPath(glyphPath(part), tint);
          }
        }
        final drawn = partialGlyphPath(part, draw);
        if (glow != null) {
          glow
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke + 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          canvas.drawPath(drawn, glow);
        }
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(drawn, paint);
      }
      canvas.restore();
    }

    // Láser de escaneo (loop sweep): barre de arriba abajo, en el rojo de marca.
    if (f.looping && !f.breathing && spec.loop == IconLoop.sweep) {
      final y = 4 + 16 * hump(f.loopT);
      final laser = Paint()
        ..isAntiAlias = true
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6
        ..color = (accentColor ?? AppColors.brand).withValues(alpha: opacity);
      canvas.drawLine(Offset(3.5, y), Offset(20.5, y), laser);
    }

    // Anillo sintético de "buscando" si el dibujo no trae piezas ds-p-ring.
    if (f.looping &&
        !f.breathing &&
        spec.loop == IconLoop.locate &&
        !glyph.parts.any((p) => p.has('ring'))) {
      final ring = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = paintColor.withValues(alpha: (1 - f.loopT) * opacity);
      canvas.drawCircle(const Offset(12, 12), 4 + 7 * f.loopT, ring);
    }

    canvas.restore();
  }

  void _applyMotion(
    IconMotion motion,
    double t,
    void Function(double cx, double cy, Matrix4 inner) around,
    Matrix4 m,
  ) {
    switch (motion) {
      case IconMotion.spin:
        around(12, 12, Matrix4.rotationZ(easeInOut(t) * 2 * math.pi));
      case IconMotion.pulse:
        final s = 1 + 0.18 * hump(t);
        around(12, 12, Matrix4.diagonal3Values(s, s, 1));
      case IconMotion.bounce:
        _translate(m, 0, -3.5 * hump(t) + 1 * hump(segment(t, .6, 1)));
      case IconMotion.pop:
        final s = popScale(t, peak: 1.25);
        around(12, 12, Matrix4.diagonal3Values(s, s, 1));
      case IconMotion.wiggle:
        around(12, 12, Matrix4.rotationZ(0.24 * damped(t, cycles: 1.5)));
      case IconMotion.nudgeRight:
        _translate(m, 3.5 * hump(t), 0);
      case IconMotion.nudgeLeft:
        _translate(m, -3.5 * hump(t), 0);
      case IconMotion.nudgeUp:
        _translate(m, 0, -3.5 * hump(t));
      case IconMotion.nudgeDown:
        _translate(m, 0, 3.5 * hump(t));
      case IconMotion.swing:
        around(12, 22, Matrix4.rotationZ(0.21 * damped(t, cycles: 1.2)));
      case IconMotion.blink:
        final s = 1 - 0.9 * hump(t);
        around(12, 12, Matrix4.diagonal3Values(1, s, 1));
      case IconMotion.draw:
      case IconMotion.stagger:
      case IconMotion.fillUp:
        break;
    }
  }

  @override
  bool shouldRepaint(_AppIconPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.accentColor != accentColor ||
      old.highlight != highlight ||
      old.successHighlight != successHighlight ||
      old.spec != spec;
}

/// `Matrix4.translate` de vector_math 2.1 recibe `dynamic` y lanza
/// `UnimplementedError` si le llega un `int`: este helper fija los tipos.
void _translate(Matrix4 m, double x, double y) =>
    m.multiply(Matrix4.translationValues(x, y, 0));
