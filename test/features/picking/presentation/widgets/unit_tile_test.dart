import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/features/picking/presentation/widgets/unit_tile.dart';

import '../../picking_test_harness.dart';
import '../../../../support/app_icon_finders.dart';
import '../../../../support/button_finders.dart';

// Fila de un producto del pedido. La acción es simple y única: imprimir la
// etiqueta ("Imprimir etiqueta" / "Imprimir de nuevo"). El escaneo de
// verificación es GLOBAL (vive en la tarjeta de progreso), no por ítem.

class _Taps {
  int printed = 0;
}

Future<_Taps> _pump(
  WidgetTester tester, {
  required bool prepared,
  bool busy = false,
  String labelId = 'LBL-00000001',
  String sku = '123',
  int lineNumber = 2,
}) async {
  final taps = _Taps();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UnitTile(
          label: buildLabel(labelId: labelId, sku: sku, lineNumber: lineNumber),
          prepared: prepared,
          busy: busy,
          onPrint: () => taps.printed++,
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  testWidgets('por preparar: imprime directo, sin escaneo por ítem', (
    tester,
  ) async {
    await _pump(tester, prepared: false, sku: '789', lineNumber: 4);

    expect(find.text('789'), findsOneWidget);
    expect(find.text('Línea 4'), findsOneWidget);
    expect(find.text('Por preparar'), findsOneWidget);
    expect(
      findButtonWithText<FilledButton>('Imprimir etiqueta'),
      findsOneWidget,
    );
    // El escaneo ya NO está por ítem (es una acción global del pedido).
    expect(find.text('Verificar con escaneo'), findsNothing);
    expect(find.textContaining('EAN'), findsNothing);
  });

  testWidgets('preparado muestra pastilla "Preparado" y reimpresión', (
    tester,
  ) async {
    await _pump(tester, prepared: true);

    expect(find.text('Preparado'), findsOneWidget);
    expect(
      findButtonWithText<FilledButton>('Imprimir de nuevo'),
      findsOneWidget,
    );
  });

  testWidgets('al tocar imprime', (tester) async {
    final taps = await _pump(tester, prepared: false);
    await tester.tap(find.text('Imprimir etiqueta'));
    await tester.pump();
    expect(taps.printed, 1);
  });

  testWidgets('busy deshabilita el botón y muestra el spinner de impresión', (
    tester,
  ) async {
    final taps = await _pump(tester, prepared: false, busy: true);

    expect(
      findAppIconInState(AppIcon.printing, AppIconState.loading),
      findsOneWidget,
    );
    final btn = tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Imprimir etiqueta'),
    );
    expect(btn.onPressed, isNull);

    await tester.tap(findButton<FilledButton>());
    await tester.pump();
    expect(taps.printed, 0);
  });

  testWidgets('no muestra ids sueltos del label (solo la línea)', (
    tester,
  ) async {
    await _pump(tester, prepared: false, labelId: 'ABC123', lineNumber: 1);

    expect(find.text('Línea 1'), findsOneWidget);
    expect(find.textContaining('ABC123'), findsNothing);
  });
}
