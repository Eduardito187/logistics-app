import 'package:flutter/widgets.dart';

/// Relleno inferior para el último contenido de un scroll de las pestañas del
/// shell.
///
/// La barra de navegación FLOTA sobre el contenido (el shell usa
/// `extendBody: true`), así que sin este relleno el último ítem queda tapado por
/// la barra. El `Scaffold` del shell propaga el alto de la barra flotante a
/// `MediaQuery.padding.bottom`, de modo que este valor:
///  - como pestaña del shell vale el alto de la barra (+ el inset del dispositivo),
///  - como ruta a pantalla completa (sin barra) vale solo el inset del dispositivo,
///
/// y no sobra espacio en ninguno de los dos casos (las pantallas del rol se usan
/// de las dos formas). Se suma [base] (16 por defecto) como respiro propio del
/// contenido.
double navScrollBottomPadding(BuildContext context, {double base = 16}) =>
    base + MediaQuery.paddingOf(context).bottom;
