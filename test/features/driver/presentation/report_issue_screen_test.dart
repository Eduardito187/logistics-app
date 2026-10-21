import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/features/driver/presentation/report_issue_screen.dart';

import '../../../support/screen_sizes.dart';
import '../support/driver_test_support.dart';

// Reporte de un inconveniente que NO cierra la entrega (POST
// /app/deliveries/{shipmentId}/issues, encolado offline con Idempotency-Key).

List<Object> _overrides(FakeOfflineQueue queue) => [
  offlineQueueProvider.overrideWithValue(queue),
  locationServiceProvider.overrideWithValue(
    FakeLocationService(fix: const GpsFix(lat: -17.7, lng: -63.1)),
  ),
];

FilledButton _send(WidgetTester tester) => tester.widget<FilledButton>(
  find.ancestor(
    of: find.text('Enviar reporte'),
    matching: find.byWidgetPredicate((w) => w is FilledButton),
  ),
);

void main() {
  testWidgets('elige el tipo y encola el reporte con el envío y el GPS', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.queued);
    await pumpPushed(
      tester,
      child: ReportIssueScreen(stop: buildStop(shipmentId: 'ship-7')),
      overrides: _overrides(queue),
      tall: true,
    );

    expect(_send(tester).onPressed, isNull); // sin tipo no se envía
    await tester.tap(find.text('Demora o tráfico'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '  Embotellamiento  ');
    await tester.tap(find.text('Enviar reporte'));
    await tester.pumpAndSettle();

    expect(queue.lastKind, 'reportDeliveryIssue');
    final payload = queue.submissions.single;
    expect(payload['@shipmentId'], 'ship-7');
    expect(
      payload['type'],
      DeliveryIssueType.delay,
    ); // se serializa como "DELAY" al encolar
    expect(payload['note'], 'Embotellamiento');
    expect(payload['lat'], -17.7);
    // Offline invisible: se informa "Registrado." y vuelve a la entrega.
    expect(find.text('Registrado.'), findsOneWidget);
    expect(find.byType(ReportIssueScreen), findsNothing);
  });

  testWidgets('"Otro" exige contar qué pasa', (tester) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpPushed(
      tester,
      child: ReportIssueScreen(stop: buildStop()),
      overrides: _overrides(queue),
      tall: true,
    );

    await tester.tap(find.text('Otro'));
    await tester.pump();
    expect(find.text('Contanos qué pasa (obligatorio)'), findsOneWidget);
    expect(_send(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Perro suelto en la puerta');
    await tester.pump();
    expect(_send(tester).onPressed, isNotNull);
  });

  testOnScreens('sin desbordes con letra grande', (tester, screen) async {
    await pumpScoped(
      tester,
      overrides: _overrides(FakeOfflineQueue(SubmitOutcome.sent)),
      child: withTextScale(ReportIssueScreen(stop: buildStop())),
    );
    expect(find.text('Reportar un inconveniente'), findsOneWidget);
  });
}
