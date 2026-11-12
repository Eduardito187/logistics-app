import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/icons/icons.dart';
import 'package:logistics_app/features/picking/presentation/widgets/progress_card.dart';
import '../../../../support/app_icon_finders.dart';
import '../../../../support/button_finders.dart';

// Tarjeta de progreso del armado: contadores preparadas/pendientes, el carril
// asignado y las acciones a nivel pedido. Etiquetas permanentes: NO hay
// "Reemitir/Anular" (una etiqueta nunca se invalida ni se regenera).

class _Taps {
  int assign = 0;
  int printAll = 0;
}

Future<_Taps> _pump(
  WidgetTester tester, {
  required int prepared,
  required int total,
  String? lane,
  bool busy = false,
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
            onAssign: () => taps.assign++,
            onPrintAll: () => taps.printAll++,
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
    expect(find.text('Preparados'), findsOneWidget);
    expect(find.text('Por preparar'), findsOneWidget);
  });

  testWidgets('sin carril muestra "sin asignar" y el botón "Asignar"', (
    tester,
  ) async {
    await _pump(tester, prepared: 0, total: 3, lane: null);

    expect(find.text('Vehículo de reparto sin asignar'), findsOneWidget);
    expect(find.text('Asignar'), findsOneWidget);
    expect(find.text('Cambiar'), findsNothing);
  });

  testWidgets('con carril muestra su valor y el botón "Cambiar"', (
    tester,
  ) async {
    await _pump(tester, prepared: 1, total: 3, lane: 'ABC-123');

    expect(find.text('Vehículo: ABC-123'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
  });

  testWidgets('NO existe "Anular y emitir de nuevo" (etiquetas permanentes)', (
    tester,
  ) async {
    await _pump(tester, prepared: 1, total: 3, lane: 'A1');

    expect(find.text('Anular y emitir de nuevo'), findsNothing);
    expect(find.text('Reemitir'), findsNothing);
    expect(find.text('Imprimir todas las etiquetas'), findsOneWidget);
  });

  testWidgets('los callbacks se disparan al tocar las acciones', (
    tester,
  ) async {
    final taps = await _pump(tester, prepared: 1, total: 3, lane: 'A1');

    await tester.tap(find.text('Cambiar'));
    await tester.tap(find.text('Imprimir todas las etiquetas'));
    await tester.pump();

    expect(taps.assign, 1);
    expect(taps.printAll, 1);
  });

  testWidgets('busy deshabilita imprimir y muestra spinner', (tester) async {
    final taps = await _pump(
      tester,
      prepared: 0,
      total: 3,
      lane: null,
      busy: true,
    );

    expect(
      findAppIconInState(AppIcon.printing, AppIconState.loading),
      findsOneWidget,
    );

    final printBtn = tester.widget<OutlinedButton>(
      findButtonWithText<OutlinedButton>('Imprimir todas las etiquetas'),
    );
    expect(printBtn.onPressed, isNull);

    // Asignar NO depende de busy: sigue activo.
    await tester.tap(find.text('Asignar'));
    await tester.pump();
    expect(taps.assign, 1);
  });
}
