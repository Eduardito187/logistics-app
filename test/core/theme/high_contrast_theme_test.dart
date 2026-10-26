import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/theme/app_colors.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/widgets/stat_tile.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';

import '../../support/screen_sizes.dart';

// Tema de alto contraste (sol fuerte): fondo blanco puro, texto negro, sin
// grises claros y todos los pares texto/fondo clave con contraste >= 7:1
// (WCAG AAA), calculado con computeLuminance.

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final theme = AppTheme.highContrast();
  final scheme = theme.colorScheme;

  test('se cachea y conserva la base de campo', () {
    expect(identical(AppTheme.highContrast(), AppTheme.highContrast()), isTrue);
    expect(theme.brightness, Brightness.light);
    expect(theme.visualDensity, VisualDensity.standard);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(theme.splashFactory, InkRipple.splashFactory);
  });

  test('marca AppContrast solo en el tema de alto contraste', () {
    expect(theme.extension<AppContrast>()?.high, isTrue);
    expect(AppTheme.light().extension<AppContrast>()?.high ?? false, isFalse);
    expect(AppTheme.dark().extension<AppContrast>()?.high ?? false, isFalse);
  });

  test('fondo blanco puro, texto negro y sin superficies grises', () {
    expect(theme.scaffoldBackgroundColor, Colors.white);
    expect(scheme.surface, Colors.white);
    expect(scheme.onSurface, AppColors.hcInk);
    expect(scheme.onSurfaceVariant, AppColors.hcInk);
    expect(scheme.outline, AppColors.hcInk);
    for (final c in [
      scheme.surfaceContainerLowest,
      scheme.surfaceContainerLow,
      scheme.surfaceContainer,
      scheme.surfaceContainerHigh,
      scheme.surfaceContainerHighest,
    ]) {
      expect(c, Colors.white);
    }
    expect(theme.textTheme.bodyMedium?.color, AppColors.hcInk);
    expect(theme.textTheme.titleLarge?.color, AppColors.hcInk);
  });

  test('pares texto/fondo clave con contraste >= 7:1', () {
    final pairs = <String, (Color, Color)>{
      'texto/fondo': (scheme.onSurface, theme.scaffoldBackgroundColor),
      'body/fondo': (theme.textTheme.bodyMedium!.color!, scheme.surface),
      'onPrimary/primary': (scheme.onPrimary, scheme.primary),
      'primary/fondo': (scheme.primary, scheme.surface),
      'onSecondary/secondary': (scheme.onSecondary, scheme.secondary),
      'onError/error': (scheme.onError, scheme.error),
      'error/fondo': (scheme.error, scheme.surface),
      'appBar': (
        theme.appBarTheme.foregroundColor!,
        theme.appBarTheme.backgroundColor!,
      ),
      'tarjeta': (scheme.onSurface, theme.cardTheme.color!),
      'snack': (
        theme.snackBarTheme.contentTextStyle!.color!,
        theme.snackBarTheme.backgroundColor!,
      ),
    };
    pairs.forEach((name, pair) {
      expect(
        _contrast(pair.$1, pair.$2),
        greaterThanOrEqualTo(7),
        reason: name,
      );
    });
  });

  test(
    'colores de pastilla y métricas en alto contraste >= 7:1 sobre blanco',
    () {
      for (final tone in PillTone.values) {
        expect(
          _contrast(StatusPill.highContrastColorFor(tone), Colors.white),
          greaterThanOrEqualTo(7),
          reason: tone.name,
        );
      }
      for (final c in [
        AppColors.success,
        AppColors.warning,
        AppColors.danger,
        AppColors.info,
        AppColors.brand,
      ]) {
        expect(
          _contrast(StatTile.highContrastTint(c), Colors.white),
          greaterThanOrEqualTo(7),
        );
      }
    },
  );

  test('bordes gruesos en tarjetas y campos', () {
    final card = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(card.side.width, AppTheme.highContrastBorder);
    expect(card.side.color, AppColors.hcInk);
    final input = theme.inputDecorationTheme.enabledBorder!;
    expect(input.borderSide.width, greaterThanOrEqualTo(2));
  });

  testOnScreens('controles miden al menos 48 dp en alto contraste', (
    tester,
    _,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.highContrast(),
        home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                key: const Key('icon'),
                tooltip: 'Linterna',
                onPressed: () {},
                icon: const Icon(Icons.flash_on),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton(
                key: const Key('filled'),
                onPressed: () {},
                child: const Text('Confirmar entrega'),
              ),
              Switch(key: const Key('switch'), value: true, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );
    for (final key in ['icon', 'filled', 'switch']) {
      final size = tester.getSize(find.byKey(Key(key)));
      expect(size.height, greaterThanOrEqualTo(48), reason: key);
    }
    expect(
      tester.getSize(find.byKey(const Key('filled'))).height,
      greaterThanOrEqualTo(AppTheme.primaryButtonHeight),
    );
  });
}
