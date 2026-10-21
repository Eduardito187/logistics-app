import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/theme/app_theme.dart';

import '../../support/screen_sizes.dart';

// Tema de campo: objetivos táctiles >= 48 dp (se usa con guantes), botones
// principales de 56 dp, sin shader de sparkle y armado una sola vez.
void main() {
  test('el tema se cachea (no se recalcula la paleta en cada build)', () {
    expect(identical(AppTheme.light(), AppTheme.light()), isTrue);
    expect(identical(AppTheme.dark(), AppTheme.dark()), isTrue);
    expect(AppTheme.dark().brightness, Brightness.dark);
  });

  test('densidad estándar, tap target padded y ripple liviano', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(theme.visualDensity, VisualDensity.standard);
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      expect(theme.splashFactory, InkRipple.splashFactory);
    }
  });

  testOnScreens(
    'controles comunes miden al menos 48 dp',
    (tester, _) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  key: const Key('icon'),
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
                OutlinedButton(
                  key: const Key('outlined'),
                  onPressed: () {},
                  child: const Text('Cancelar'),
                ),
                Row(
                  children: [
                    TextButton(
                      key: const Key('text'),
                      onPressed: () {},
                      child: const Text('Ok'),
                    ),
                    ElevatedButton(
                      key: const Key('elevated'),
                      onPressed: () {},
                      child: const Text('Imprimir'),
                    ),
                  ],
                ),
                const ListTile(key: Key('tile'), title: Text('Parada 1')),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      for (final key in ['icon', 'text', 'tile']) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.width, greaterThanOrEqualTo(48), reason: key);
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
      }
      for (final key in ['filled', 'outlined', 'elevated']) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(
          size.height,
          greaterThanOrEqualTo(AppTheme.primaryButtonHeight),
          reason: key,
        );
      }
    },
    screens: const [TestScreen.smallPhone, TestScreen.tabletLandscape],
  );
}
