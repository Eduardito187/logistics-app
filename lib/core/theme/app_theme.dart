import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_contrast.dart';

export 'app_contrast.dart';

/// Tema de campo: objetivos táctiles grandes y texto legible bajo el sol.
/// La app se usa con guantes, con una mano y en movimiento.
///
/// Expone claro (por defecto, mejor bajo el sol) y oscuro (turnos de noche y
/// vistas de mapa). Los tamaños de botón y tipografía se fijan acá: las
/// pantallas no los sobreescriben.
abstract final class AppTheme {
  /// Lado mínimo de cualquier objetivo táctil (con guantes). Material pide 48;
  /// es el piso, no el tamaño típico (los botones principales miden 56).
  static const double minTouchTarget = 48;

  /// Alto de los botones principales (escanear, confirmar, entregar).
  static const double primaryButtonHeight = 56;

  // El tema se arma una sola vez: `ColorScheme.fromSeed` calcula toda la
  // paleta tonal y `LogisticsApp.build` corre en cada cambio de sesión/push.
  static final ThemeData _light = _build(Brightness.light);
  static final ThemeData _dark = _build(Brightness.dark);

  static ThemeData light() => _light;

  static ThemeData dark() => _dark;

  /// Alto contraste para sol fuerte: fondo blanco puro, texto negro, colores
  /// semánticos oscuros (≥ 7:1 sobre blanco) y bordes gruesos. También cacheado.
  static ThemeData highContrast() => _highContrast;

  static final ThemeData _highContrast = _buildHighContrast();

  /// Grosor de borde de tarjetas, campos y pastillas en alto contraste.
  static const double highContrastBorder = 2;

  static ThemeData _buildHighContrast() {
    const ink = AppColors.hcInk;
    const white = Colors.white;
    const border = BorderSide(color: ink, width: highContrastBorder);
    // Reusa el tema claro ya armado (no recalcula la paleta tonal).
    final base = _light;

    // Sin grises claros ni tintes: todas las superficies son blancas y todo
    // lo que va encima es negro o un semántico oscuro.
    final scheme = base.colorScheme.copyWith(
      primary: AppColors.hcBrand,
      onPrimary: white,
      primaryContainer: AppColors.hcBrand,
      onPrimaryContainer: white,
      // El ámbar de marca con tinta Noche supera 10:1: se conserva como acento.
      secondary: AppColors.accent,
      onSecondary: ink,
      secondaryContainer: AppColors.accent,
      onSecondaryContainer: ink,
      tertiary: AppColors.hcInfo,
      onTertiary: white,
      error: AppColors.hcDanger,
      onError: white,
      errorContainer: AppColors.hcDanger,
      onErrorContainer: white,
      surface: white,
      onSurface: ink,
      onSurfaceVariant: ink,
      surfaceDim: white,
      surfaceBright: white,
      surfaceContainerLowest: white,
      surfaceContainerLow: white,
      surfaceContainer: white,
      surfaceContainerHigh: white,
      surfaceContainerHighest: white,
      surfaceTint: Colors.transparent,
      outline: ink,
      outlineVariant: ink,
      inverseSurface: ink,
      onInverseSurface: white,
    );

    final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: white,
      canvasColor: white,
      dividerColor: ink,
      textTheme: text,
      iconTheme: const IconThemeData(color: ink),
      dividerTheme: const DividerThemeData(color: ink, thickness: 2),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: white,
        foregroundColor: ink,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(color: ink),
        shape: const Border(bottom: border),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: border,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: const WidgetStatePropertyAll(ink),
          side: const WidgetStatePropertyAll(border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: const WidgetStatePropertyAll(AppColors.hcBrand),
        ),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: ink,
        textColor: ink,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: white,
        labelStyle: const TextStyle(color: ink),
        hintStyle: const TextStyle(color: AppColors.hcNeutral),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: border,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: border,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.hcBrand, width: 3),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: white,
        labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w700),
        side: border,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: white, fontSize: 16),
        actionTextColor: AppColors.accent,
      ),
      extensions: const [AppContrast(high: true)],
    );
  }

  /// Pone Barlow Condensed 800 en los títulos (display/headline/title) y deja
  /// el resto en Barlow (familia base del tema). Conserva tamaños y colores.
  static TextTheme _brandTextTheme(TextTheme t) {
    TextStyle? head(TextStyle? s) =>
        s?.copyWith(fontFamily: 'BarlowCondensed', fontWeight: FontWeight.w800);
    return t.copyWith(
      displayLarge: head(t.displayLarge),
      displayMedium: head(t.displayMedium),
      displaySmall: head(t.displaySmall),
      headlineLarge: head(t.headlineLarge),
      headlineMedium: head(t.headlineMedium),
      headlineSmall: head(t.headlineSmall),
      titleLarge: head(t.titleLarge),
    );
  }

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      // En oscuro el rojo pleno vibra; se usa un rojo claro legible como primario.
      primary: isDark ? const Color(0xFFFF8A80) : AppColors.brand,
      secondary: AppColors.accent,
      error: AppColors.danger,
    ).copyWith(
      // El seed rojo tiñe de rosa los roles neutros que M3 deriva (íconos
      // funcionales, bordes, divisores, texto secundario). Se fijan a gris
      // real: el rojo queda para marca y acción, no para la "tinta" de la UI.
      onSurfaceVariant: isDark
          ? const Color(0xFFC9C9C9)
          : const Color(0xFF4A4A4A),
      outline: isDark ? const Color(0xFF8E8E8E) : const Color(0xFF787878),
      outlineVariant: isDark
          ? const Color(0xFF3A3A3A)
          : const Color(0xFFD9D9D9),
    );

    // ThemeData.textTheme solo trae colores y pesos; los tamaños viven en la
    // geometría (typography.englishLike) que Flutter combina recién en
    // Theme.of. Escalar sin tamaños dispara una aserción de TextStyle.apply,
    // así que primero se combinan y luego se escala.
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      // Barlow es la tipografía base de marca (texto, botones, wordmark).
      fontFamily: 'Barlow',
    );
    // Títulos en Barlow Condensed 800 (señalética vial); el resto en Barlow.
    final sizedText = _brandTextTheme(
      base.typography.englishLike.merge(base.textTheme),
    );

    return base.copyWith(
      scaffoldBackgroundColor: isDark
          ? AppColors.nightBg
          : AppColors.platformLight,
      // Densidad estándar: `comfortable` resta 4 dp a botones y objetivos
      // táctiles (un IconButton quedaba en 44x44, debajo del mínimo de 48).
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // InkRipple en vez de InkSparkle (default M3 en Android): el sparkle usa
      // un shader que en GPUs de gama baja traba el primer toque.
      splashFactory: InkRipple.splashFactory,
      // Íconos funcionales (acciones de AppBar, list tiles, íconos de tarjeta)
      // en tinta neutra, nunca rojo: el rojo es marca/acción, no decoración de
      // íconos. Botones y pastillas fijan su propio color y no se ven afectados.
      iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.nightBg),
      // Transiciones baratas: la default de Android (Zoom) captura la pantalla
      // en una textura y en Skia compila shaders la primera vez (tirón al abrir
      // cada pantalla en gama baja). FadeUpwards es un fundido + desplazamiento
      // corto sin captura; en iOS se mantiene el deslizado nativo.
      pageTransitionsTheme: _pageTransitions,
      textTheme: sizedText.apply(fontSizeFactor: 1.1),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.nightBg,
        titleTextStyle: TextStyle(
          fontFamily: 'BarlowCondensed',
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : AppColors.nightBg,
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
          minimumSize: const Size.fromHeight(primaryButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Ancho mínimo finito: puede ir dentro de un Row sin Expanded.
          minimumSize: const Size(64, primaryButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        // Íconos de lista en tinta neutra (no el rojo tonal que M3 derivaría).
        iconColor: isDark ? Colors.white : AppColors.nightBg,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(primaryButtonHeight),
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
