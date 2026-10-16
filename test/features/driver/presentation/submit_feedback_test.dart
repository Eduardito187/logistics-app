import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/submit_feedback.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/theme/app_colors.dart';

// Mapeo compartido del desenlace offline-first (lo usan scan_units, pod y
// failed_delivery del chofer vía showSubmitOutcome). Se documenta el mensaje y
// color de cada desenlace: enviado / en cola (sin red) / error.

void main() {
  group('submitOutcomeMessage', () {
    test('enviado', () {
      expect(submitOutcomeMessage(SubmitOutcome.sent), 'Registrado y enviado.');
    });
    test('en cola (sin red)', () {
      expect(
        submitOutcomeMessage(SubmitOutcome.queued),
        'Guardado sin conexión. Se enviará al recuperar señal.',
      );
    });
    test('error', () {
      expect(
        submitOutcomeMessage(SubmitOutcome.failed),
        'No se pudo registrar. Revísalo en Sincronización.',
      );
    });
  });

  group('submitOutcomeColor', () {
    test('colores semánticos por desenlace', () {
      expect(submitOutcomeColor(SubmitOutcome.sent), AppColors.success);
      expect(submitOutcomeColor(SubmitOutcome.queued), AppColors.warning);
      expect(submitOutcomeColor(SubmitOutcome.failed), AppColors.danger);
    });
  });

  testWidgets('showSubmitOutcome muestra el SnackBar del desenlace', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSubmitOutcome(context, SubmitOutcome.queued),
              child: const Text('x'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('x'));
    await tester.pump();

    expect(
      find.text('Guardado sin conexión. Se enviará al recuperar señal.'),
      findsOneWidget,
    );
  });
}
