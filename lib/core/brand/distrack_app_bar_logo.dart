import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logotipo DisTrack para la fila superior (toolbar) de un [AppBar].
///
/// Elige la variante del SVG según el brillo del tema para que SIEMPRE sea
/// legible: en tema claro usa el logo oscuro (#141414 + #E30613) y en tema
/// oscuro usa la variante invertida (blanco + #E30613). Pensado como `title`
/// de un `SliverAppBar`/`AppBar` con `centerTitle: false`, de modo que quede
/// pegado a la izquierda, frente a las acciones de la derecha.
class DisTrackAppBarLogo extends StatelessWidget {
  const DisTrackAppBarLogo({super.key, this.height = 26});

  /// Alto del logo en píxeles lógicos (~24–28 queda prolijo en el toolbar).
  final double height;

  static const String _light = 'assets/brand/distrack-logo.svg';
  static const String _dark = 'assets/brand/distrack-logo-inverse.svg';

  @override
  Widget build(BuildContext context) {
    // AppBar clara → logo oscuro; AppBar Noche → logo invertido.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      isDark ? _dark : _light,
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: 'DisTrack',
    );
  }
}
