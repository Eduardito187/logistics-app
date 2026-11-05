import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/core/widgets/field_icon.dart';

import '../../support/app_icon_finders.dart';

// FieldIcon: el prefijo de input. Antes el AnimatedAppIcon (CustomPaint) se
// estiraba a llenar las min-constraints del slot del prefijo (~44) e ignoraba
// `size`, por eso se veía gigante. Estos tests fijan que el ícono se dibuje
// EXACTAMENTE a `size` dentro del campo.

void main() {
  Future<void> pumpField(
    WidgetTester tester, {
    double size = 24,
    FocusNode? node,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            focusNode: node,
            decoration: InputDecoration(
              labelText: 'Campo',
              prefixIconConstraints: FieldIcon.prefixConstraints,
              prefixIcon: FieldIcon(
                icon: AppIcon.profile,
                focusNode: node,
                size: size,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('el ícono se dibuja a `size` (no se infla a la caja de 44)', (
    tester,
  ) async {
    await pumpField(tester, size: 24);

    // El AnimatedAppIcon queda contenido en su SizedBox de 24, NO en los 44 del
    // slot del prefijo (que antes lo estiraban y lo hacían gigante). El test
    // fallaría si volviera a inflarse (~44).
    final iconSize = tester.getSize(findAppIcon(AppIcon.profile));
    expect(iconSize.width, closeTo(24, 0.5));
    expect(iconSize.height, closeTo(24, 0.5));
  });

  testWidgets('respeta un size distinto', (tester) async {
    await pumpField(tester, size: 20);
    final iconSize = tester.getSize(findAppIcon(AppIcon.profile));
    expect(iconSize.width, closeTo(20, 0.5));
  });

  testWidgets('sin focusNode no falla y queda tenue (idle)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextField(
            decoration: InputDecoration(
              prefixIconConstraints: FieldIcon.prefixConstraints,
              prefixIcon: FieldIcon(icon: AppIcon.qrCode),
            ),
          ),
        ),
      ),
    );
    expect(
      findAppIconInState(AppIcon.qrCode, AppIconState.idle),
      findsOneWidget,
    );
    expect(tester.getSize(findAppIcon(AppIcon.qrCode)).width, closeTo(24, 0.5));
  });
}
