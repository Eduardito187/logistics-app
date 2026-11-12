import 'package:flutter/widgets.dart';

/// Cierra el teclado del sistema en cada cambio de ruta.
///
/// Si un campo de texto tenía el foco en la pantalla que se abandona (p. ej. el
/// login o un buscador), el teclado quedaba abierto SOBRE la pantalla siguiente,
/// que a veces ni tiene inputs. Al navegar se quita el foco primario y el
/// teclado baja.
///
/// Los diálogos/pantallas que SÍ quieren el teclado (campos con `autofocus`) lo
/// vuelven a pedir después del push: su autofoco corre al construirse la nueva
/// ruta, después de este `didPush`, así que no se ven afectados.
class KeyboardDismissObserver extends NavigatorObserver {
  void _dismiss() {
    final focus = FocusManager.instance.primaryFocus;
    // Solo si de verdad hay algo enfocado (evita trabajo y reconstrucciones
    // innecesarias cuando no había teclado abierto).
    if (focus != null && focus.hasFocus) focus.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _dismiss();
}
