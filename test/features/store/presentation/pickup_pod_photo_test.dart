import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/store/domain/usecases/enqueue_delivery_photo.dart';
import 'package:logistics_app/features/store/domain/usecases/record_pod.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/pickup_pod_screen.dart';

import '../../../support/button_finders.dart';
import '../../../support/fake_code_scanner.dart';
import '../../../support/fake_photo_picker.dart';
import '../store_fixtures.dart';
import '../store_test_harness.dart';

// Recojo en tienda: foto de evidencia (cámara falsa vía `photoPickerProvider`)
// y avisos que flotan encima del botón fijo "Escanear y entregar bulto".

final _shipment = shipment(customerName: 'Ana Pérez');

/// Cola de fotos falsa: registra lo encolado o falla si [fail].
class _FakeEnqueuePhoto extends EnqueueDeliveryPhoto {
  _FakeEnqueuePhoto(super.ref, this.calls, {this.fail = false});

  final List<Map<String, String>> calls;
  final bool fail;

  @override
  Future<void> call({
    required String shipmentId,
    required String filePath,
    required String kind,
  }) async {
    if (fail) throw Exception('disco lleno');
    calls.add({'shipmentId': shipmentId, 'filePath': filePath, 'kind': kind});
  }
}

/// POD falso: registra la marca de foto de cada entrega.
class _FakeRecordPod extends RecordPod {
  _FakeRecordPod(super.ref, this.photoPaths);

  final List<String?> photoPaths;

  @override
  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required String confirmation,
    required String customerName,
    String? photoPath,
  }) async {
    photoPaths.add(photoPath);
    return SubmitOutcome.sent;
  }
}

class _Harness {
  final enqueued = <Map<String, String>>[];
  final podPhotoPaths = <String?>[];
  late FakePhotoPicker camera;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  List<String?> photos = const [],
  List<String?> codes = const [],
  bool enqueueFails = false,
}) async {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = _Harness()..camera = FakePhotoPicker(photos);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        shipmentUnitsProvider(
          _shipment.id,
        ).overrideWith((ref) async => [unit(unitId: 'unit-1')]),
        photoPickerProvider.overrideWithValue(h.camera.call),
        enqueueDeliveryPhotoProvider.overrideWith(
          (ref) => _FakeEnqueuePhoto(ref, h.enqueued, fail: enqueueFails),
        ),
        recordPodProvider.overrideWith(
          (ref) => _FakeRecordPod(ref, h.podPhotoPaths),
        ),
        codeScannerProvider.overrideWithValue(FakeCodeScanner(codes).call),
        labelScannerProvider.overrideWithValue(LabelScanner(null)),
      ],
      child: MaterialApp(home: PickupPodScreen(shipment: _shipment)),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

Future<void> _tapTakePhoto(WidgetTester tester, String label) async {
  await tester.tap(findButtonWithText<OutlinedButton>(label));
  await tester.pumpAndSettle();
}

Future<void> _deliver(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'QR del cliente o documento'),
    'CI-1',
  );
  await tester.pumpAndSettle();
  await tester.tap(
    findButtonWithText<FilledButton>('Escanear y entregar bulto'),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tomar foto: se pide reducida, se encola con la ruta y se ve', (
    tester,
  ) async {
    final h = await _pump(tester, photos: ['/tmp/pod-1.jpg']);

    await _tapTakePhoto(tester, 'Tomar foto');

    expect(h.camera.requests, [
      (maxWidth: kEvidencePhotoMaxWidth, imageQuality: kEvidencePhotoQuality),
    ]);
    expect(h.enqueued, [
      {'shipmentId': _shipment.id, 'filePath': '/tmp/pod-1.jpg', 'kind': 'pod'},
    ]);
    expect(find.text('Foto guardada'), findsOneWidget);
    expect(find.text('Volver a tomar'), findsOneWidget);
    // La vista previa se decodifica acotada (no la foto completa).
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, kPhotoPreviewCacheWidth);
  });

  testWidgets('con foto: el POD viaja con la marca de foto adjunta', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      photos: ['/tmp/pod-1.jpg'],
      codes: ['unit-1'],
    );

    await _tapTakePhoto(tester, 'Tomar foto');
    await _deliver(tester);

    expect(h.podPhotoPaths, ['pendiente']);
  });

  testWidgets('cancelar la cámara: no encola ni adjunta foto', (tester) async {
    final h = await _pump(tester, photos: [null], codes: ['unit-1']);

    await _tapTakePhoto(tester, 'Tomar foto');

    expect(h.camera.requests, hasLength(1));
    expect(h.enqueued, isEmpty);
    expect(find.text('Foto guardada'), findsNothing);
    expect(find.byType(Image), findsNothing);

    await _deliver(tester);
    expect(h.podPhotoPaths, [null]);
  });

  testWidgets('volver a tomar encola la nueva foto', (tester) async {
    final h = await _pump(tester, photos: ['/tmp/a.jpg', '/tmp/b.jpg']);

    await _tapTakePhoto(tester, 'Tomar foto');
    await _tapTakePhoto(tester, 'Volver a tomar');

    expect(h.enqueued.map((e) => e['filePath']), ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('si no se pudo guardar la foto avisa y no la adjunta', (
    tester,
  ) async {
    final h = await _pump(tester, photos: ['/tmp/a.jpg'], enqueueFails: true);

    await _tapTakePhoto(tester, 'Tomar foto');

    expect(
      find.text('No se pudo guardar la foto. Intentá de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Foto guardada'), findsNothing);
    expect(h.enqueued, isEmpty);
  });

  testWidgets('el aviso de entrega flota encima del botón fijo del pie', (
    tester,
  ) async {
    await _pump(tester, codes: ['unit-1']);

    await _deliver(tester);

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snack.margin,
      const EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance),
    );
  });

  testWidgets('el aviso de bulto ajeno también flota encima del botón', (
    tester,
  ) async {
    await _pump(tester, codes: ['unit-de-otro']);

    await _deliver(tester);

    expect(find.text('Ese bulto no pertenece a este pedido.'), findsOneWidget);
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snack.margin,
      const EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance),
    );
  });
}
