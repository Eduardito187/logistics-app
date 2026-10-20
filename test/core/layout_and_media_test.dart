import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/layout/responsive_body.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';

import '../support/screen_sizes.dart';

// Base de la fase de optimización: breakpoints, ancho máximo en tablets y
// avisos cortos que no tapan el botón del pie.

void main() {
  test('breakpoints: compacto, mediano y expandido', () {
    expect(AppBreakpoints.sizeFor(320), WindowSize.compact);
    expect(AppBreakpoints.sizeFor(599), WindowSize.compact);
    expect(AppBreakpoints.sizeFor(600), WindowSize.medium);
    expect(AppBreakpoints.sizeFor(840), WindowSize.expanded);
    expect(AppBreakpoints.columnsFor(360), 1);
    expect(AppBreakpoints.columnsFor(800), 2);
    expect(AppBreakpoints.columnsFor(1280), 3);
  });

  testOnScreens('ResponsiveBody limita el ancho solo en pantallas anchas', (
    tester,
    screen,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveBody(child: SizedBox.expand(key: Key('content'))),
        ),
      ),
    );
    final width = tester.getSize(find.byKey(const Key('content'))).width;
    expect(
      width,
      screen.size.width > AppBreakpoints.maxContentWidth
          ? AppBreakpoints.maxContentWidth
          : screen.size.width,
    );
  });

  testWidgets('aviso de éxito dura 2 s y el de error 4 s', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    showSuccessSnack(ctx, 'ok', bottomClearance: kBottomActionClearance);
    await tester.pump();
    final ok = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(ok.duration, kShortSnackDuration);
    expect(ok.margin, const EdgeInsets.fromLTRB(16, 0, 16, 96));

    showErrorSnack(ctx, 'mal');
    await tester.pump();
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar).last).duration,
      kErrorSnackDuration,
    );
  });
}
