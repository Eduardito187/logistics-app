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
      expect(submitOutcomeMessage(SubmitOutcome.sent), 'Registrado.');
    });
    test('queued', () {
      expect(submitOutcomeMessage(SubmitOutcome.queued), 'Registrado.');
    });
    test('failed', () {
      expect(
        submitOutcomeMessage(SubmitOutcome.failed),
        'No se pudo registrar. Intentá de nuevo.',
      );
    });
    test('failed con failureDetail -> muestra el motivo real del backend', () {
      expect(
        submitOutcomeMessage(
          SubmitOutcome.failed,
          failureDetail: 'no hay entrega abierta para el envío X',
        ),
        'no hay entrega abierta para el envío X',
      );
    });
    test('failureDetail vacío/espacios -> cae al genérico', () {
      expect(
        submitOutcomeMessage(SubmitOutcome.failed, failureDetail: '   '),
        'No se pudo registrar. Intentá de nuevo.',
      );
    });
    test('failureDetail se ignora si NO falló (sent/queued)', () {
      expect(
        submitOutcomeMessage(SubmitOutcome.sent, failureDetail: 'x'),
        'Registrado.',
      );
      expect(
        submitOutcomeMessage(SubmitOutcome.queued, failureDetail: 'x'),
        'Registrado.',
      );
    });
  });

  group('submitOutcomeColor', () {
    test('sent → verde éxito', () {
      expect(submitOutcomeColor(SubmitOutcome.sent), AppColors.success);
    });
    test('queued → verde, igual que enviado (offline invisible)', () {
      expect(submitOutcomeColor(SubmitOutcome.queued), AppColors.success);
    });
    test('failed → rojo peligro', () {
      expect(submitOutcomeColor(SubmitOutcome.failed), AppColors.danger);
    });
  });

  group('showSubmitOutcome', () {
    testWidgets('sent muestra mensaje y color de éxito', (tester) async {
      await _pumpAndShow(tester, SubmitOutcome.sent);
      expect(find.text('Registrado.'), findsOneWidget);
      expect(_snackBar(tester).backgroundColor, AppColors.success);
      expect(_snackBar(tester).behavior, SnackBarBehavior.floating);
    });

    testWidgets('queued se ve igual que enviado (offline invisible)', (
      tester,
    ) async {
      await _pumpAndShow(tester, SubmitOutcome.queued);
      expect(find.text('Registrado.'), findsOneWidget);
      expect(_snackBar(tester).backgroundColor, AppColors.success);
    });

    testWidgets('failed muestra mensaje y color de peligro', (tester) async {
      await _pumpAndShow(tester, SubmitOutcome.failed);
      expect(
        find.text('No se pudo registrar. Intentá de nuevo.'),
        findsOneWidget,
      );
      expect(_snackBar(tester).backgroundColor, AppColors.danger);
    });

    testWidgets('failed con failureDetail muestra el motivo real', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSubmitOutcome(
                  context,
                  SubmitOutcome.failed,
                  failureDetail: 'no hay entrega abierta para el envío X',
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(
        find.text('no hay entrega abierta para el envío X'),
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
        find.text('No se pudo registrar. Intentá de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Registrado.'), findsNothing);
    });
  });
}
