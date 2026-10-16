import 'package:flutter/material.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/incident_screen.dart';

import '../support/driver_test_support.dart';

// Reporte de incidente del vehículo. No requiere escaneo; sí GPS (opcional) y la
// cola offline. MINOR retrasa ETAs; MAJOR saca de servicio.

Future<FakeOfflineQueue> _pumpIncident(
  WidgetTester tester,
  SubmitOutcome outcome,
) async {
  final queue = FakeOfflineQueue(outcome);
  await pumpScoped(
    tester,
    overrides: [...gateBase(), offlineQueueProvider.overrideWithValue(queue)],
    child: const IncidentScreen(),
    tall: true,
  );
  return queue;
}

void main() {
  testWidgets('muestra tipos, gravedades y sus pistas', (tester) async {
    await _pumpIncident(tester, SubmitOutcome.sent);

    expect(find.text('Reportar incidente'), findsWidgets);
    expect(find.text('Avería'), findsOneWidget);
    expect(find.text('Accidente'), findsOneWidget);
    expect(find.text('Menor'), findsOneWidget);
    expect(find.text('Grave'), findsOneWidget);
    expect(find.text('La ruta sigue con ETAs retrasadas.'), findsOneWidget);
    expect(
      find.text('Vehículo fuera de servicio; se reprograma al día siguiente.'),
      findsOneWidget,
    );
  });

  testWidgets('reporte enviado muestra el aviso y encola el incidente', (
    tester,
  ) async {
    final queue = await _pumpIncident(tester, SubmitOutcome.sent);

    await tester.tap(find.widgetWithText(FilledButton, 'Reportar incidente'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Registrado y enviado.'), findsOneWidget);
    expect(queue.lastKind, 'reportVehicleIncident');
    // Payload incluye el id del vehículo asignado.
    expect(queue.submissions.single['@vehicleId'], 'v1');
  });

  testWidgets('sin red queda en cola', (tester) async {
    await _pumpIncident(tester, SubmitOutcome.queued);

    await tester.tap(find.widgetWithText(FilledButton, 'Reportar incidente'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Guardado sin conexión. Se enviará al recuperar señal.'),
      findsOneWidget,
    );
  });

  testWidgets('error de datos no cierra la pantalla', (tester) async {
    await _pumpIncident(tester, SubmitOutcome.failed);

    await tester.tap(find.widgetWithText(FilledButton, 'Reportar incidente'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(
      find.text('No se pudo registrar. Revísalo en Sincronización.'),
      findsOneWidget,
    );
    // No hace pop: el formulario sigue en pantalla.
    expect(find.text('Tipo de incidente'), findsOneWidget);
  });
}
