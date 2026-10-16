import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/scan_outcome_pill.dart';

// Pastilla del resultado de un escaneo offline-first: enviado / pendiente /
// error, cada uno con su etiqueta, tono e ícono.

Future<StatusPill> _pill(WidgetTester tester, SubmitOutcome outcome) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ScanOutcomePill(outcome))),
  );
  return tester.widget<StatusPill>(find.byType(StatusPill));
}

void main() {
  testWidgets('enviado → éxito con ícono cloud_done', (tester) async {
    final pill = await _pill(tester, SubmitOutcome.sent);
    expect(pill.label, 'Enviado');
    expect(pill.tone, PillTone.success);
    expect(pill.icon, Icons.cloud_done);
  });

  testWidgets('encolado → info con ícono sync', (tester) async {
    final pill = await _pill(tester, SubmitOutcome.queued);
    expect(pill.label, 'Pendiente');
    expect(pill.tone, PillTone.info);
    expect(pill.icon, Icons.sync);
  });

  testWidgets('fallido → peligro con ícono error', (tester) async {
    final pill = await _pill(tester, SubmitOutcome.failed);
    expect(pill.label, 'Error');
    expect(pill.tone, PillTone.danger);
    expect(pill.icon, Icons.error_outline);
  });
}
