import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/driver/domain/store_stop.dart';
import 'package:logistics_app/features/driver/presentation/controllers/locally_settled_stops.dart';
import 'package:logistics_app/features/driver/presentation/store_drop_screen.dart';

import '../../../support/button_finders.dart';
import '../../../support/fake_code_scanner.dart';
import '../../../support/fake_photo_picker.dart';
import '../support/driver_test_support.dart';

// "Entregar en tienda": el camión DEJA el pedido en la tienda. Solo escaneo de
// productos + foto (sin firma). Cierra la parada con `store-drop`, que deja el
// pedido "listo para retirar" (no entregado) y avisa al cliente.

/// Cola de fotos falsa: registra el `kind` de lo encolado.
class _PhotoQueue implements PhotoUploadQueue {
  final List<String> kinds = [];

  @override
  Future<void> enqueue({
    required String shipmentId,
    required String filePath,
    required String kind,
    Map<String, Object?>? clientSnapshot,
  }) async {
    kinds.add(kind);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// QR de etiqueta abierta (sin firma) de un producto de la orden [order].
String _qr(String id, {String order = 'DM-1'}) =>
    '{"v":1,"t":"PKG","k":0,"id":"$id","o":"$order","ln":1,"sku":"SKU-1",'
    '"u":[1,1],"pc":[1,1],"org":"CD01","dst":"T","ts":1700000000,"s":""}';

DriverRouteStop _storeStop({List<String>? unitIds}) => buildStop(
  customerName: 'Ana Pérez',
  orderReference: 'DM-1',
  deliveryMode: DeliveryMode.storePickup,
  destinationNodeId: 'node-store',
  destinationNodeName: 'Tienda Santa Cruz Norte',
  unitIds: unitIds,
);

FilledButton _register(WidgetTester tester) => tester.widget<FilledButton>(
  findButtonWithText<FilledButton>('Registrar entrega en tienda'),
);

void main() {
  test('isStoreStop: tienda solo con store_pickup o transfer', () {
    bool isStore(DeliveryMode mode) =>
        isStoreStop(buildStop(deliveryMode: mode));
    expect(isStore(DeliveryMode.storePickup), isTrue);
    expect(isStore(DeliveryMode.transfer), isTrue);
    expect(isStore(DeliveryMode.homeDelivery), isFalse);
    // Backend anterior (sin el campo): entrega a domicilio, como siempre.
    expect(isStoreStop(buildStop()), isFalse);
  });

  testWidgets('pide productos y foto; NO pide firma ni documento', (
    tester,
  ) async {
    await pumpScoped(
      tester,
      child: StoreDropScreen(stop: _storeStop()),
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
      ],
      tall: true,
    );

    expect(find.text('Entregar en tienda'), findsOneWidget);
    expect(find.text('Tienda Santa Cruz Norte'), findsOneWidget);
    expect(find.text('Pedido DM-1'), findsOneWidget);
    expect(find.text('1. Productos que dejás'), findsOneWidget);
    expect(find.text('2. Foto de entrega (obligatoria)'), findsOneWidget);
    expect(find.textContaining('Firma del cliente'), findsNothing);
    expect(find.textContaining('Documento'), findsNothing);
    expect(_register(tester).onPressed, isNull);
  });

  testWidgets('escaneo + foto → descarga por producto y cierre store-drop', (
    tester,
  ) async {
    final queue = FakeOfflineQueue(SubmitOutcome.sent);
    final photos = _PhotoQueue();
    await pumpScoped(
      tester,
      child: StoreDropScreen(stop: _storeStop(unitIds: ['u1', 'u2'])),
      overrides: [
        codeScannerProvider.overrideWithValue(
          FakeCodeScanner([_qr('u1'), _qr('u2')]).call,
        ),
        labelScannerProvider.overrideWithValue(vectorLabelScanner()),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        photoPickerProvider.overrideWithValue(
          FakePhotoPicker(['/tmp/tienda.jpg']).call,
        ),
        photoUploadQueueProvider.overrideWithValue(photos),
        offlineQueueProvider.overrideWithValue(queue),
      ],
      tall: true,
    );

    // Se toma antes de registrar: al cerrar, la pantalla se va.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StoreDropScreen)),
    );

    await tester.tap(find.text('Escanear producto'));
    await tester.pumpAndSettle();
    // Con un solo producto de dos todavía no se puede registrar.
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(_register(tester).onPressed, isNull);

    await tester.tap(find.text('Escanear siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Escaneados 2 de 2'), findsOneWidget);
    expect(_register(tester).onPressed, isNotNull);

    await tester.tap(find.text('Registrar entrega en tienda'));
    await tester.pumpAndSettle();

    expect(photos.kinds, ['pod']);
    expect(queue.kinds, [
      'recordUnloadScan',
      'recordUnloadScan',
      'recordStoreDrop',
    ]);
    // El cierre va al envío de la parada y a SU tienda; nunca es un POD.
    expect(queue.submissions.last['@shipmentId'], 'ship-1');
    expect(queue.submissions.last['node_id'], 'node-store');
    expect(queue.kinds, isNot(contains('recordProofOfDelivery')));
    // La parada queda resuelta en el teléfono al instante.
    expect(
      container.read(locallySettledStopsProvider)['stop-1'],
      DriverRouteStopStatus.completed,
    );
  });

  testWidgets('un producto de otro pedido no se acepta', (tester) async {
    await pumpScoped(
      tester,
      child: StoreDropScreen(stop: _storeStop()),
      overrides: [
        codeScannerProvider.overrideWithValue(
          FakeCodeScanner([_qr('u9', order: 'DM-OTRO')]).call,
        ),
        labelScannerProvider.overrideWithValue(vectorLabelScanner()),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
      ],
      tall: true,
    );

    await tester.tap(find.text('Escanear producto'));
    await tester.pumpAndSettle();

    expect(find.text('Ese producto es de otro pedido.'), findsOneWidget);
    expect(find.text('Escaneá cada producto que dejás.'), findsOneWidget);
  });
}
