import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/submit_feedback.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/theme/app_colors.dart';

Future<void> _pumpAndShow(WidgetTester tester, SubmitOutcome outcome) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showSubmitOutcome(context, outcome),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pump();
}

SnackBar _snackBar(WidgetTester tester) =>
    tester.widget<SnackBar>(find.byType(SnackBar));

void main() {
  group('submitOutcomeMessage', () {
    test('sent', () {
      expect(submitOutcomeMessage(SubmitOutcome.sent), 'Registrado y enviado.');
    });
    test('queued', () {
      expect(
        submitOutcomeMessage(SubmitOutcome.queued),
        'Guardado sin conexión. Se enviará al recuperar señal.',
      );
    });
    test('failed', () {
      expect(
        submitOutcomeMessage(SubmitOutcome.failed),
        'No se pudo registrar. Revísalo en Sincronización.',
      );
    });
  });

  group('submitOutcomeColor', () {
    test('sent → verde éxito', () {
      expect(submitOutcomeColor(SubmitOutcome.sent), AppColors.success);
    });
    test('queued → ámbar advertencia', () {
      expect(submitOutcomeColor(SubmitOutcome.queued), AppColors.warning);
    });
    test('failed → rojo peligro', () {
      expect(submitOutcomeColor(SubmitOutcome.failed), AppColors.danger);
    });
  });

  group('showSubmitOutcome', () {
    testWidgets('sent muestra mensaje y color de éxito', (tester) async {
      await _pumpAndShow(tester, SubmitOutcome.sent);
      expect(find.text('Registrado y enviado.'), findsOneWidget);
      expect(_snackBar(tester).backgroundColor, AppColors.success);
      expect(_snackBar(tester).behavior, SnackBarBehavior.floating);
    });

    testWidgets('queued muestra mensaje y color de advertencia', (
      tester,
    ) async {
      await _pumpAndShow(tester, SubmitOutcome.queued);
      expect(
        find.text('Guardado sin conexión. Se enviará al recuperar señal.'),
        findsOneWidget,
      );
      expect(_snackBar(tester).backgroundColor, AppColors.warning);
    });

    testWidgets('failed muestra mensaje y color de peligro', (tester) async {
      await _pumpAndShow(tester, SubmitOutcome.failed);
      expect(
        find.text('No se pudo registrar. Revísalo en Sincronización.'),
        findsOneWidget,
      );
      expect(_snackBar(tester).backgroundColor, AppColors.danger);
    });

    testWidgets('limpia el SnackBar anterior antes de mostrar el nuevo', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        showSubmitOutcome(context, SubmitOutcome.sent),
                    child: const Text('sent'),
                  ),
                  ElevatedButton(
                    onPressed: () =>
                        showSubmitOutcome(context, SubmitOutcome.failed),
                    child: const Text('failed'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('sent'));
      await tester.pump();
      await tester.tap(find.text('failed'));
      await tester.pump();
      // clearSnackBars() dejó un único SnackBar visible: el último.
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('No se pudo registrar. Revísalo en Sincronización.'),
        findsOneWidget,
      );
      expect(find.text('Registrado y enviado.'), findsNothing);
    });
  });
}
