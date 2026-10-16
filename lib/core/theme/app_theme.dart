import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema de campo: objetivos táctiles grandes y texto legible bajo el sol.
/// La app se usa con guantes, con una mano y en movimiento.
///
/// Expone claro (por defecto, mejor bajo el sol) y oscuro (turnos de noche y
/// vistas de mapa). Los tamaños de botón y tipografía se fijan acá: las
/// pantallas no los sobreescriben.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      primary: isDark ? const Color(0xFF6FA8FF) : AppColors.brand,
      secondary: AppColors.accent,
      error: AppColors.danger,
    );

    // ThemeData.textTheme solo trae colores y pesos; los tamaños viven en la
    // geometría (typography.englishLike) que Flutter combina recién en
    // Theme.of. Escalar sin tamaños dispara una aserción de TextStyle.apply,
    // así que primero se combinan y luego se escala.
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final sizedText = base.typography.englishLike.merge(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: isDark
          ? AppColors.nightBg
          : const Color(0xFFF4F6F8),
      visualDensity: VisualDensity.comfortable,
      textTheme: sizedText.apply(fontSizeFactor: 1.1),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF101418),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF101418),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.nightSurface : Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E6EA),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.nightSurfaceHigh : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
