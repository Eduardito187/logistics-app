import 'package:flutter/material.dart';

/// Paleta de marca DisTrack. Acento rojo fuerte y fondo "Noche" para alto
/// contraste bajo el sol; el ámbar queda reservado a alertas/pendientes
/// (nunca en el logo). Se conservan los nombres de símbolo históricos para no
/// tocar el resto de la app.
abstract final class AppColors {
  const AppColors._();

  // Rojo Dismac: color de marca y de la acción principal.
  static const Color brand = Color(0xFFE30613);
  static const Color brandDark = Color(0xFFB00510);

  // "Ámbar seguridad": acento de alertas y estados "en curso"/pendientes.
  // Nunca va en el logo (regla de marca); con tinta Noche se lee de sobra.
  static const Color accent = Color(0xFFFFB000);
  static const Color accentInk = Color(0xFF141414);

  // Semánticos de estado operativo.
  static const Color success = Color(0xFF1E8E3E);
  static const Color warning = Color(0xFFFFB000);
  static const Color danger = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1565C0);

  // Superficies "Noche" (modo oscuro / vista de mapa / fondo de marca).
  static const Color nightBg = Color(0xFF141414);
  static const Color nightSurface = Color(0xFF1E1E1E);
  static const Color nightSurfaceHigh = Color(0xFF262626);

  // "Andén": fondo claro de la marca (reemplaza el gris azulado anterior).
  static const Color platformLight = Color(0xFFF3F3F1);

  // Alto contraste (sol fuerte): sobre blanco puro todos superan 7:1 (WCAG
  // AAA). Los usa `AppTheme.highContrast()` y las pastillas de estado.
  static const Color hcInk = Color(0xFF000000);
  static const Color hcBrand = brandDark;
  static const Color hcNeutral = Color(0xFF263038);
  static const Color hcSuccess = Color(0xFF0A5C1F);
  static const Color hcWarning = Color(0xFF7A4100);
  static const Color hcDanger = Color(0xFF9B0000);
  static const Color hcInfo = Color(0xFF0A3D91);
}
