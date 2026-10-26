import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/driver/presentation/failed_delivery_screen.dart';

import '../../../support/fake_code_scanner.dart';
import '../support/driver_test_support.dart';
import '../../../support/button_finders.dart';

// Entrega fallida: bulto + motivo tipado + foto opcional + GPS.
//
// El bulto se escanea vía codeScannerProvider y se verifica offline con el
// vector Ed25519 compartido. La foto usa image_picker (sin seam) y es opcional,
// así que los flujos se ejercitan sin foto.

List<Object> _overrides(
  FakeCodeScanner fake, {
  FakeOfflineQueue? queue,
  GpsFix? fix,
}) => [
  codeScannerProvider.overrideWithValue(fake.call),
  labelScannerProvider.overrideWithValue(vectorLabelScanner()),
  locationServiceProvider.overrideWithValue(FakeLocationService(fix: fix)),
  if (queue != null) offlineQueueProvider.overrideWithValue(queue),
];

FilledButton _registerButton(WidgetTester tester) =>
    tester.widget<FilledButton>(
      findButtonWithText<FilledButton>('Registrar entrega fallida'),
    );

void main() {
  testWidgets('render con los motivos y botón deshabilitado sin bulto', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      tall: true,
    );

    expect(find.text('Entrega fallida'), findsWidgets);
    expect(find.text('1. Bulto'), findsOneWidget);
    expect(find.text('Escanea el bulto.'), findsOneWidget);

    // Motivos tipados (FailureReason) en español.
    expect(find.text('Cliente ausente'), findsOneWidget);
    expect(find.text('Dirección incorrecta'), findsOneWidget);
    expect(find.text('Pedido rechazado'), findsOneWidget);
    expect(find.text('Producto dañado'), findsOneWidget);
    expect(find.text('Otro motivo'), findsOneWidget);

    expect(_registerButton(tester).onPressed, isNull);
  });

  testWidgets('al entrar calienta el GPS sin esperarlo', (tester) async {
    final location = FakeLocationService();
    await pumpScoped(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      overrides: [locationServiceProvider.overrideWithValue(location)],
      tall: true,
    );

    expect(location.prefetchCount, 1);
  });

  testWidgets('se puede elegir otro motivo', (tester) async {
    await pumpScoped(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      tall: true,
    );

    // Elegir "Producto dañado" no debe fallar (cambia el radio seleccionado).
    await tester.tap(find.text('Producto dañado'));
    await tester.pump();
    expect(find.text('Producto dañado'), findsOneWidget);
  });

  testWidgets(
    'camino feliz: escanea el bulto, elige motivo, registra y vuelve',
    (tester) async {
      final fake = FakeCodeScanner([validLabelQr()]);
      final queue = FakeOfflineQueue(SubmitOutcome.sent);
      await pumpPushed(
        tester,
        child: FailedDeliveryScreen(stop: buildStop(shipmentId: 'ship-7')),
        overrides: _overrides(
          fake,
          queue: queue,
          fix: const GpsFix(lat: -17.7, lng: -63.1),
        ),
        tall: true,
      );

      await tester.tap(find.text('Escanear bulto'));
      await tester.pumpAndSettle();
      expect(find.text('Bulto: $vectorUnitId'), findsOneWidget);
      expect(find.text('Reescanear'), findsOneWidget);
      expect(fake.requestedTitles, ['Escanear bulto']);
      expect(find.byType(ScannerScreen), findsNothing);

      await tester.tap(find.text('Producto dañado'));
      await tester.pump();

      expect(_registerButton(tester).onPressed, isNotNull);
      await tester.tap(find.text('Registrar entrega fallida'));
      await tester.pumpAndSettle();

      expect(queue.lastKind, 'recordFailedDelivery');
      final payload = queue.submissions.single;
      expect(payload['shipment_id'], 'ship-7');
      expect(payload['unit_id'], vectorUnitId);
      // El modelo generado deja el enum en el mapa (se serializa al enviar).
      expect(payload['reason'], anyOf(FailureReason.damaged, 'DAMAGED'));
      expect(payload['lat'], -17.7);
      expect(payload['lng'], -63.1);

      expect(find.text('Registrado.'), findsOneWidget);
      expect(find.byType(FailedDeliveryScreen), findsNothing);
      expect(find.text('Inicio'), findsOneWidget);
    },
  );

  testWidgets('motivo por defecto: cliente ausente', (tester) async {
    final queue = FakeOfflineQueue(SubmitOutcome.queued);
    await pumpPushed(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([validLabelQr()]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar entrega fallida'));
    await tester.pumpAndSettle();

    expect(
      queue.submissions.single['reason'],
      anyOf(FailureReason.customerAbsent, 'CUSTOMER_ABSENT'),
    );
    expect(find.text('Registrado.'), findsOneWidget);
    expect(find.byType(FailedDeliveryScreen), findsNothing);
  });

  testWidgets('si el registro falla avisa y se queda en la pantalla', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.failed);
    await pumpPushed(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([validLabelQr()]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar entrega fallida'));
    await tester.pumpAndSettle();

    expect(queue.submissions, hasLength(1));
    expect(
      find.text('No se pudo registrar. Intentá de nuevo.'),
      findsOneWidget,
    );
    expect(find.byType(FailedDeliveryScreen), findsOneWidget);
    expect(_registerButton(tester).onPressed, isNotNull);
  });

  testWidgets('cancelar el escaneo no toma bulto ni envía', (tester) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([null]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
    await tester.pumpAndSettle();

    expect(find.text('Escanea el bulto.'), findsOneWidget);
    expect(find.text('Etiqueta no válida'), findsNothing);
    expect(_registerButton(tester).onPressed, isNull);
    expect(queue.submissions, isEmpty);
  });

  testWidgets('etiqueta con firma inválida: avisa y no toma el bulto', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    await pumpScoped(
      tester,
      child: FailedDeliveryScreen(stop: buildStop()),
      overrides: _overrides(FakeCodeScanner([tamperedLabelQr()]), queue: queue),
      tall: true,
    );

    await tester.tap(find.text('Escanear bulto'));
    await tester.pumpAndSettle();

    expect(find.text('Etiqueta no válida'), findsOneWidget);
    expect(find.text('Escanea el bulto.'), findsOneWidget);
    expect(_registerButton(tester).onPressed, isNull);
    expect(queue.submissions, isEmpty);
  });
}
