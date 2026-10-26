import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/widgets/async_value_view.dart';
import 'package:logistics_app/core/widgets/brand_loader.dart';
import 'package:logistics_app/core/widgets/stat_tile.dart';

import '../../support/screen_sizes.dart';

// Widgets compartidos livianos y sin desbordes en pantallas chicas.
void main() {
  testWidgets('AsyncValueView loading aísla el loader en un RepaintBoundary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncValueView<int>(
            value: const AsyncValue.loading(),
            data: (v) => Text('$v'),
          ),
        ),
      ),
    );
    expect(find.byType(LoadingView), findsOneWidget);
    // El RepaintBoundary más cercano es el padre directo del loader de marca:
    // su animación repinta seguido y el límite evita arrastrar al resto.
    final boundary = tester.widget<RepaintBoundary>(
      find
          .ancestor(
            of: find.byType(BrandLoader),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    expect(boundary.child, isA<BrandLoader>());
  });

  testOnScreens(
    'StatTile con número largo no desborda de a dos por fila',
    (tester, _) async {
      await tester.pumpWidget(
        MaterialApp(
          home: withTextScale(
            Scaffold(
              // Como en las features: dos mosaicos en un Row con Expanded.
              body: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: StatTile(
                        value: 'Bs 1.234.567,89',
                        label: 'Cobrado contra entrega en el turno de hoy',
                        icon: Icons.payments,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: StatTile(value: '128', label: 'Entregas'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Bs 1.234.567,89'), findsOneWidget);
    },
    screens: const [TestScreen.smallPhone, TestScreen.phone],
  );
}
