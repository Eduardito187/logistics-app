import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Centra el contenido y lo limita a [maxWidth] en pantallas anchas (tablets),
/// sin cambiar nada en teléfonos. Envolver el `body` de pantallas de lista o
/// formulario: `ResponsiveBody(child: ListView(...))`.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
