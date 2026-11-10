import 'package:flutter/material.dart';

import '../icons/icons.dart';

/// Ícono chico y prolijo para el `prefixIcon` de CUALQUIER campo de texto de la
/// app (login, 2FA, emitir etiquetas, armado, impresora, recepción…). Antes
/// cada pantalla metía un `AnimatedAppIcon` crudo como prefijo: salía al tamaño
/// por defecto (24) y, como los glyphs custom se dibujan de borde a borde (sin
/// el margen interno de `Icon`), se veían gigantes e inconsistentes dentro del
/// input. Acá van a un [size] FIJO (24 por defecto) centrado en una caja de 44;
/// lo clave es que el glyph se dibuja exactamente a `size` y NO se infla a la
/// caja del prefijo (ver build).
///
/// Si se pasa un [focusNode], además reacciona al FOCO: crece muy poco y pasa a
/// [AppIconState.active] (el motor lo ilumina/llena con su metáfora: la persona
/// se rellena, el candado se cierra). Sin `focusNode` queda tenue y estático
/// (los formularios sin un nodo por campo igual se ven parejos). Respeta
/// "reducir movimiento".
class FieldIcon extends StatefulWidget {
  const FieldIcon({
    super.key,
    required this.icon,
    this.focusNode,
    this.size = 24,
  });

  final AppIcon icon;

  /// Nodo de foco del campo; si es `null`, el ícono no reacciona al foco.
  final FocusNode? focusNode;
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
    _focused = widget.focusNode?.hasFocus ?? false;
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(FieldIcon old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
      _focused = widget.focusNode?.hasFocus ?? false;
    }
  }

  void _onFocusChange() {
    final focused = widget.focusNode?.hasFocus ?? false;
    if (!mounted || focused == _focused) return;
    setState(() => _focused = focused);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final icon = AnimatedScale(
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
    // CLAVE: el `AnimatedAppIcon` es un `CustomPaint` que SIN un tamaño fijo se
    // ESTIRA a llenar las min-constraints del slot del prefijo (≈44) e ignora
    // el `size` → por eso antes se veía gigante con 24, 18 y 16 por igual (no
    // cambiaba nada). Se arma una caja fija de 44 (el espacio del prefijo) y el
    // ícono va en un `SizedBox` de `size` CENTRADO: el `Center` le da
    // restricciones sueltas, así el glyph se dibuja exactamente a `size`.
    return SizedBox.square(
      dimension: 44,
      child: Center(
        child: SizedBox.square(dimension: widget.size, child: icon),
      ),
    );
  }
}
