import 'package:flutter/material.dart';

/// Tema de campo: objetivos táctiles grandes y texto legible bajo el sol.
/// La app se usa con guantes, con una mano y en movimiento.
abstract final class AppTheme {
  static const _seed = Color(0xFF0B4DA2);

  static ThemeData light() {
    // ThemeData.textTheme solo trae colores y pesos; los tamaños viven en la geometría
    // (typography.englishLike) que Flutter combina recién en Theme.of. Escalar sin tamaños
    // dispara una aserción de TextStyle.apply, así que primero se combinan y luego se escala.
    final base = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed));
    final sizedText = base.typography.englishLike.merge(base.textTheme);

    return base.copyWith(
      visualDensity: VisualDensity.comfortable,
      textTheme: sizedText.apply(fontSizeFactor: 1.1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
