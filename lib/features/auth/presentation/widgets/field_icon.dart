import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';

/// Ícono de un campo de formulario (el `prefixIcon`) chico y prolijo que
/// reacciona al FOCO: al enfocar el campo crece un poco (suave) y pasa a
/// [AppIconState.active], así el motor lo ilumina/llena en el color de marca y
/// reproduce su metáfora (la persona se rellena, el candado se cierra, el sobre
/// se abre); al desenfocar vuelve a su estado tenue.
///
/// Sin rebotes por cada tecla (se veía nervioso): la reacción es solo al
/// enfocar, limpia. Los glyphs custom se dibujan de borde a borde del box (sin
/// el margen interno que trae `Icon`), así que a igual [size] se ven más
/// grandes; por eso el prefix va chico ([size] 18) para que no se vea gigante
/// ni grueso. Respeta "reducir movimiento": ahí no crece, solo cambia de color.
class FieldIcon extends StatefulWidget {
  const FieldIcon({
    super.key,
    required this.icon,
    required this.focusNode,
    this.size = 18,
  });

  final AppIcon icon;
  final FocusNode focusNode;
  final double size;

  /// Restricciones estándar para el `prefixIcon`: deja el ícono chico centrado
  /// en una caja táctil cómoda sin inflar el alto del campo.
  static const BoxConstraints prefixConstraints = BoxConstraints(
    minWidth: 44,
    minHeight: 44,
  );

  @override
  State<FieldIcon> createState() => _FieldIconState();
}

class _FieldIconState extends State<FieldIcon> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(FieldIcon old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _focused = widget.focusNode.hasFocus;
    }
  }

  void _onFocusChange() {
    if (!mounted || widget.focusNode.hasFocus == _focused) return;
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      // Crecimiento muy sutil al enfocar (antes 1.12 se veía inflado).
      scale: _focused && !reduce ? 1.08 : 1.0,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedAppIcon(
        widget.icon,
        state: _focused ? AppIconState.active : AppIconState.idle,
        size: widget.size,
        color: muted,
        excludeFromSemantics: true,
      ),
    );
  }
}
