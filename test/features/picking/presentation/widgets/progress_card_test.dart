import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/presentation/widgets/button_spinner.dart';
import 'package:logistics_app/features/picking/presentation/widgets/progress_card.dart';
import '../../../../support/button_finders.dart';

// Tarjeta de progreso del armado: contadores preparadas/pendientes, el carril
// asignado y las acciones a nivel pedido.

class _Taps {
  int assign = 0;
  int printAll = 0;
  int reprint = 0;
}

Future<_Taps> _pump(
  WidgetTester tester, {
  required int prepared,
  required int total,
  String? lane,
  bool busy = false,
  bool reprinting = false,
}) async {
  final taps = _Taps();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProgressCard(
            prepared: prepared,
            total: total,
            lane: lane,
            busy: busy,
            reprinting: reprinting,
            onAssign: () => taps.assign++,
            onPrintAll: () => taps.printAll++,
            onReprintBatch: () => taps.reprint++,
          ),
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  testWidgets('muestra el conteo preparadas/total y pendientes', (
    tester,
  ) async {
    await _pump(tester, prepared: 2, total: 5, lane: 'Carril 3');

    expect(find.text('2/5'), findsOneWidget); // preparadas
    expect(find.text('3'), findsOneWidget); // pendientes = total - prepared
    expect(find.text('Preparadas'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
  });

  testWidgets('sin carril muestra "sin asignar" y el botón "Asignar"', (
    tester,
  ) async {
    await _pump(tester, prepared: 0, total: 3, lane: null);

    expect(find.text('Carril / vehículo sin asignar'), findsOneWidget);
    expect(find.text('Asignar'), findsOneWidget);
    expect(find.text('Cambiar'), findsNothing);
  });

  testWidgets('con carril muestra su valor y el botón "Cambiar"', (
    tester,
  ) async {
    await _pump(tester, prepared: 1, total: 3, lane: 'ABC-123');

    expect(find.text('Carril / vehículo: ABC-123'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
  });

  testWidgets('los callbacks se disparan al tocar las acciones', (
    tester,
  ) async {
    final taps = await _pump(tester, prepared: 1, total: 3, lane: 'A1');

    await tester.tap(find.text('Cambiar'));
    await tester.tap(find.text('Imprimir todas las etiquetas'));
    await tester.tap(find.text('Reimprimir lote'));
    await tester.pump();

    expect(taps.assign, 1);
    expect(taps.printAll, 1);
    expect(taps.reprint, 1);
  });

  testWidgets('busy deshabilita imprimir/reimprimir y muestra spinner', (
    tester,
  ) async {
    final taps = await _pump(
      tester,
      prepared: 0,
      total: 3,
      lane: null,
      busy: true,
    );

    // El botón "Imprimir todas" muestra el spinner en vez del ícono.
    expect(find.byType(ButtonSpinner), findsOneWidget);

    final printBtn = tester.widget<OutlinedButton>(
      findButtonWithText<OutlinedButton>('Imprimir todas las etiquetas'),
    );
    final reprintBtn = tester.widget<OutlinedButton>(
      findButtonWithText<OutlinedButton>('Reimprimir lote'),
    );
    expect(printBtn.onPressed, isNull);
    expect(reprintBtn.onPressed, isNull);

    // Asignar NO depende de busy: sigue activo.
    await tester.tap(find.text('Asignar'));
    await tester.pump();
    expect(taps.assign, 1);
  });

  testWidgets(
    'reprinting: el spinner va en "Reimprimir lote", no en imprimir',
    (tester) async {
      await _pump(
        tester,
        prepared: 0,
        total: 3,
        lane: null,
        busy: true,
        reprinting: true,
      );

      expect(
        find.descendant(
          of: findButtonWithText<OutlinedButton>('Reimprimir lote'),
          matching: find.byType(ButtonSpinner),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: findButtonWithText<OutlinedButton>(
            'Imprimir todas las etiquetas',
          ),
          matching: find.byType(ButtonSpinner),
        ),
        findsNothing,
      );
    },
  );
}
