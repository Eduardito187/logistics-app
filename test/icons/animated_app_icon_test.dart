import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/icons/generated/app_icon_glyphs.g.dart';
import 'package:logistics_app/core/icons/icon_glyph.dart';
import 'package:logistics_app/core/icons/icon_motion.dart';
import 'package:logistics_app/core/icons/icons.dart';

import '../support/app_icon_finders.dart';

// Set de íconos custom animados DisTrack (docs/custom-animated-icons-brief.md):
// cobertura del catálogo, dibujo válido y comportamiento de cada estado.

Widget _host(Widget child, {bool reduceMotion = false, bool dark = false}) =>
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  group('catálogo', () {
    test('cada AppIcon tiene dibujo, animación y etiqueta en español', () {
      for (final icon in AppIcon.values) {
        expect(kAppIconGlyphs[icon], isNotNull, reason: 'sin dibujo: $icon');
        expect(
          appIconSpecFor(icon),
          isNot(same(AppIconSpec.fallback)),
          reason: 'sin animación: $icon',
        );
        expect(icon.label.trim(), isNotEmpty, reason: 'sin etiqueta: $icon');
      }
    });

    test('cada dibujo es válido: piezas con trazo dentro de la grilla 24', () {
      for (final entry in kAppIconGlyphs.entries) {
        final parts = entry.value.parts;
        expect(parts, isNotEmpty, reason: '${entry.key} sin piezas');
        expect(
          parts.where((p) => p.accent).length,
          1,
          reason: '${entry.key} debe tener exactamente un acento',
        );
        for (final part in parts) {
          final b = glyphBounds(part);
          // Toda pieza dibuja algo: un trazo con longitud o un relleno.
          expect(
            part.fill || glyphMetrics(part).any((m) => m.length > 0),
            isTrue,
            reason: '${entry.key} tiene una pieza vacía',
          );
          expect(
            b.left >= 0 && b.top >= 0 && b.right <= 24 && b.bottom <= 24,
            isTrue,
            reason: '${entry.key} se sale de la grilla: $b',
          );
        }
      }
    });
  });

  group('render y estados', () {
    testWidgets('todos los íconos pasan por todos los estados sin errores', (
      tester,
    ) async {
      for (final dark in [false, true]) {
        for (final icon in AppIcon.values) {
          for (final state in AppIconState.values) {
            await tester.pumpWidget(
              _host(AnimatedAppIcon(icon, state: state, size: 32), dark: dark),
            );
            await tester.pump(const Duration(milliseconds: 120));
            await tester.pump(const Duration(milliseconds: 400));
          }
        }
      }
      // Cortar cualquier loop antes de terminar.
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('el loop de loading se corta al cambiar de estado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AnimatedAppIcon(AppIcon.syncing, state: AppIconState.loading),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(
        _host(
          const AnimatedAppIcon(AppIcon.syncing, state: AppIconState.success),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('con reduce motion no anima: va directo al estado final', (
      tester,
    ) async {
      for (final state in AppIconState.values) {
        await tester.pumpWidget(
          _host(
            AnimatedAppIcon(AppIcon.scan, state: state, ambient: true),
            reduceMotion: true,
          ),
        );
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse, reason: '$state');
      }
    });

    testWidgets('el botón central respira en reposo (ambient)', (tester) async {
      await tester.pumpWidget(
        _host(const AnimatedAppIcon(AppIcon.deliver, ambient: true)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('un ícono en reposo no deja animaciones corriendo', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const AnimatedAppIcon(AppIcon.home)));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('el toque aprieta el ícono y reproduce su movimiento', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const AnimatedAppIcon(AppIcon.add, size: 48)),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(findAppIcon(AppIcon.add)),
      );
      await tester.pump(const Duration(milliseconds: 40));
      expect(tester.hasRunningAnimations, isTrue);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('accesibilidad', () {
    testWidgets('anuncia la etiqueta del catálogo por defecto', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const AnimatedAppIcon(AppIcon.deliver)));
      expect(find.bySemanticsLabel('Entrega en curso'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
      'semanticLabel reemplaza a la etiqueta; excludeFromSemantics la quita',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            const Column(
              children: [
                AnimatedAppIcon(AppIcon.scan, semanticLabel: 'Escanear bulto'),
                AnimatedAppIcon(AppIcon.close, excludeFromSemantics: true),
              ],
            ),
          ),
        );
        expect(find.bySemanticsLabel('Escanear bulto'), findsOneWidget);
        expect(find.bySemanticsLabel('Cerrar'), findsNothing);
        handle.dispose();
      },
    );
  });

  testWidgets('hereda color y tamaño del IconTheme como un Icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const IconTheme(
          data: IconThemeData(size: 40, color: Colors.green),
          child: AnimatedAppIcon(AppIcon.check),
        ),
      ),
    );
    expect(tester.getSize(findAppIcon(AppIcon.check)).width, 40);
  });

  testWidgets('se anima completo sobre un botón rojo y con resalte propio', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            FilledButton.icon(
              onPressed: () {},
              icon: const AnimatedAppIcon(AppIcon.check),
              label: const Text('Terminar'),
            ),
            const AnimatedAppIcon(
              AppIcon.deliver,
              color: Colors.white,
              highlightColor: Colors.black,
              state: AppIconState.active,
              animateOnMount: true,
            ),
          ],
        ),
      ),
    );
    await tester.tap(findAppIcon(AppIcon.check));
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('GlyphPart.has lee las etiquetas de coreografía', () {
    const part = GlyphPart(cmds: [0, 1, 1, 1, 2, 2], tags: ['box']);
    expect(part.has('box'), isTrue);
    expect(part.has('lid'), isFalse);
  });
}
