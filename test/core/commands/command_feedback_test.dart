import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/commands/command_feedback.dart';
import 'package:logistics_app/core/commands/command_outcome.dart';
import 'package:logistics_app/core/theme/app_colors.dart';

/// Monta un botón que al tocarse dispara `showCommandOutcome` con [outcome],
/// así podemos inspeccionar el SnackBar resultante.
Future<void> _pumpAndTap(WidgetTester tester, CommandOutcome outcome) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showCommandOutcome(context, outcome),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pump(); // dispara la animación del SnackBar
}

SnackBar _snackBar(WidgetTester tester) =>
    tester.widget<SnackBar>(find.byType(SnackBar));

void main() {
  group('showCommandOutcome', () {
    testWidgets('applied (sync) → "Hecho." en color de éxito', (tester) async {
      await _pumpAndTap(tester, const CommandOutcome.applied());
      expect(find.text('Hecho.'), findsOneWidget);
      expect(_snackBar(tester).backgroundColor, AppColors.success);
    });

    testWidgets(
      'accepted (202 async) → "Aceptado. Se está procesando." en color info',
      (tester) async {
        await _pumpAndTap(tester, const CommandOutcome.accepted());
        expect(find.text('Aceptado. Se está procesando.'), findsOneWidget);
        // Tono informativo (azul), nunca verde: la orden NO está aplicada aún.
        expect(_snackBar(tester).backgroundColor, AppColors.info);
      },
    );

    testWidgets('applied con mensaje del backend prioriza ese texto', (
      tester,
    ) async {
      await _pumpAndTap(
        tester,
        const CommandOutcome.applied(message: 'Ruta cerrada.'),
      );
      expect(find.text('Ruta cerrada.'), findsOneWidget);
      expect(find.text('Hecho.'), findsNothing);
      expect(_snackBar(tester).backgroundColor, AppColors.success);
    });

    testWidgets('accepted con mensaje del backend prioriza ese texto', (
      tester,
    ) async {
      await _pumpAndTap(
        tester,
        const CommandOutcome.accepted(message: 'Tomamos tu solicitud.'),
      );
      expect(find.text('Tomamos tu solicitud.'), findsOneWidget);
      expect(find.text('Aceptado. Se está procesando.'), findsNothing);
      expect(_snackBar(tester).backgroundColor, AppColors.info);
    });

    testWidgets('el SnackBar es flotante', (tester) async {
      await _pumpAndTap(tester, const CommandOutcome.applied());
      expect(_snackBar(tester).behavior, SnackBarBehavior.floating);
    });
  });
}
