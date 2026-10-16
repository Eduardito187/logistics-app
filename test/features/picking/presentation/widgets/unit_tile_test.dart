import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/presentation/widgets/button_spinner.dart';
import 'package:logistics_app/features/picking/presentation/widgets/unit_tile.dart';

import '../../picking_test_harness.dart';

// Fila de una unidad del pedido. Pendiente → "Escanear EAN e imprimir";
// preparada → pastilla "Preparada" y "Reimprimir etiqueta". busy la bloquea.

class _Taps {
  int prepare = 0;
  int reprint = 0;
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
          onPrepare: () => taps.prepare++,
          onReprint: () => taps.reprint++,
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  testWidgets('pendiente muestra SKU, línea, bulto y botón de escaneo', (
    tester,
  ) async {
    await _pump(tester, prepared: false, sku: '789', lineNumber: 4);

    expect(find.text('SKU 789'), findsOneWidget);
    // Bulto = últimos 8 caracteres del labelId.
    expect(find.text('Línea 4 · Bulto …00000001'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Escanear EAN e imprimir'),
      findsOneWidget,
    );
    expect(find.text('Reimprimir etiqueta'), findsNothing);
  });

  testWidgets('preparada muestra pastilla "Preparada" y reimprimir', (
    tester,
  ) async {
    await _pump(tester, prepared: true);

    expect(find.text('Preparada'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Reimprimir etiqueta'),
      findsOneWidget,
    );
    expect(find.text('Escanear EAN e imprimir'), findsNothing);
  });

  testWidgets('al tocar dispara el callback correcto según el estado', (
    tester,
  ) async {
    var taps = await _pump(tester, prepared: false);
    await tester.tap(find.text('Escanear EAN e imprimir'));
    await tester.pump();
    expect(taps.prepare, 1);

    taps = await _pump(tester, prepared: true);
    await tester.tap(find.text('Reimprimir etiqueta'));
    await tester.pump();
    expect(taps.reprint, 1);
  });

  testWidgets('busy deshabilita el botón y muestra el spinner', (tester) async {
    final taps = await _pump(tester, prepared: false, busy: true);

    expect(find.byType(ButtonSpinner), findsOneWidget);
    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Escanear EAN e imprimir'),
    );
    expect(btn.onPressed, isNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(taps.prepare, 0);
  });

  testWidgets('labelId corto (<=8) se muestra entero como bulto', (
    tester,
  ) async {
    await _pump(tester, prepared: false, labelId: 'ABC123', lineNumber: 1);

    expect(find.text('Línea 1 · Bulto …ABC123'), findsOneWidget);
  });
}
