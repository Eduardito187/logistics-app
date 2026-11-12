import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/carrier/domain/models/carrier_scan_kind.dart';
import 'package:logistics_app/features/carrier/domain/models/queued_carrier_scan.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_deliver_screen.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_pickup_screen.dart';

import '../../store/fake_continuous_scanner.dart';
import '../../../support/button_finders.dart';
import '../../../support/fake_code_scanner.dart';
import '../carrier_scan_harness.dart';

// La tanda de escaneo del transportista no se pierde al salir de la pantalla:
// el historial (y con él el "ya recogido / ya entregado") vive en
// `carrierScanSessionProvider` y, al abrir, se rearma con lo que quedó en la
// cola offline.

/// Monta [screen] en [container] (mismo contenedor = misma "corrida de la app").
Future<void> _show(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

/// Sale de la pantalla (se desmonta) y muestra otra cosa.
Future<void> _leave(WidgetTester tester, ProviderContainer container) => _show(
  tester,
  container,
  const Scaffold(body: Center(child: Text('otra pantalla'))),
);

Future<void> _tapPickupScan(WidgetTester tester) async {
  await tester.tap(findButtonWithText<FilledButton>('Escanear producto'));
  await tester.pumpAndSettle();
}

void main() {
  late TestLabelSigner signer;
  late String qrA;

  setUpAll(() async {
    signer = await TestLabelSigner.create();
    qrA = await signer.qr(id: 'U-A', order: 'DM-1', sku: 'SKU-A');
  });

  testWidgets('recoger: salir y volver mantiene lo ya escaneado', (
    tester,
  ) async {
    final loadScan = FakeRecordLoadScan();
    final container = ProviderContainer(
      overrides: carrierScanOverrides(
        continuous: FakeContinuousScanner.sessions([
          [qrA],
          [qrA],
        ]),
        labelScanner: signer.scanner(),
        loadScan: loadScan,
      ),
    );

    await _show(tester, container, const CarrierPickupScreen());
    await _tapPickupScan(tester);
    expect(find.text('SKU-A'), findsOneWidget);

    await _leave(tester, container);
    await _show(tester, container, const CarrierPickupScreen());

    // El historial sigue ahí (no parece que no hubiera hecho nada)...
    expect(find.text('Sin productos recogidos'), findsNothing);
    expect(find.text('SKU-A'), findsOneWidget);
    expect(find.text('U-A'), findsOneWidget);
    // ...y el producto sigue contando como recogido: no se encola de nuevo.
    await _tapPickupScan(tester);
    expect(loadScan.requests, hasLength(1));

    container.dispose();
  });

  testWidgets('recoger: al abrir rearma la tanda desde la cola offline', (
    tester,
  ) async {
    final queue = FakeCarrierScanQueueSource({
      CarrierScanKind.pickup: [
        QueuedCarrierScan(
          unitId: 'U-A',
          sku: 'SKU-A',
          at: DateTime(2026, 11, 12, 9, 30),
        ),
        QueuedCarrierScan(
          unitId: 'U-B',
          sku: 'SKU-B',
          at: DateTime(2026, 11, 12, 9, 35),
        ),
      ],
    });
    final loadScan = FakeRecordLoadScan();
    final scanner = FakeContinuousScanner([qrA]);
    await pumpCarrierScanScreen(
      tester,
      const CarrierPickupScreen(),
      continuous: scanner,
      labelScanner: signer.scanner(),
      loadScan: loadScan,
      queueSource: queue,
    );

    expect(queue.queries, [CarrierScanKind.pickup]);
    expect(find.text('Sin productos recogidos'), findsNothing);
    expect(find.text('SKU-A'), findsOneWidget);
    expect(find.text('SKU-B'), findsOneWidget);
    // Lo encolado se ve como enviado (offline invisible).
    expect(find.text('Enviado'), findsNWidgets(2));

    // Lo rearmado cuenta como recogido: volver a escanearlo avisa y no encola.
    await _tapPickupScan(tester);
    expect(loadScan.requests, isEmpty);
    expect(scanner.messages, ['Ya recogido']);
  });

  testWidgets('entregar: al abrir rearma la tanda y avisa "Ya entregado"', (
    tester,
  ) async {
    final queue = FakeCarrierScanQueueSource({
      CarrierScanKind.deliver: [
        QueuedCarrierScan(
          unitId: 'U-A',
          sku: 'SKU-A',
          at: DateTime(2026, 11, 12, 10),
        ),
      ],
    });
    final pod = FakeRecordProofOfDelivery();
    final units = FakeContinuousScanner([qrA]);
    await pumpCarrierScanScreen(
      tester,
      const CarrierDeliverScreen(),
      scanner: FakeCodeScanner(['CONF-1']),
      continuous: units,
      labelScanner: signer.scanner(),
      proofOfDelivery: pod,
      queueSource: queue,
    );

    expect(queue.queries, [CarrierScanKind.deliver]);
    expect(find.text('Sin entregas registradas'), findsNothing);
    expect(find.text('SKU-A'), findsOneWidget);

    await tester.tap(findButtonWithText<FilledButton>('Registrar entrega'));
    await tester.pumpAndSettle();

    expect(pod.requests, isEmpty);
    expect(units.messages, ['Ya entregado']);
  });

  testWidgets('cola vacía: la pantalla arranca sin productos', (tester) async {
    await pumpCarrierScanScreen(tester, const CarrierPickupScreen());

    expect(find.text('Sin productos recogidos'), findsOneWidget);
  });
}
