import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/gps_fix.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/store/data/repositories/store_repository_impl.dart';
import 'package:logistics_app/features/store/domain/usecases/enqueue_delivery_photo.dart';
import 'package:logistics_app/features/store/domain/usecases/record_pod.dart';
import 'package:logistics_app/features/store/domain/usecases/upload_pod_photo.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/pickup_pod_screen.dart';

import '../../../support/button_finders.dart';
import '../../../support/fake_label_resolver.dart';
import '../../../support/fake_photo_picker.dart';
import '../fake_continuous_scanner.dart';
import '../store_fixtures.dart';
import '../store_test_harness.dart';

// Recojo en tienda: foto de evidencia (cámara falsa vía `photoPickerProvider`)
// y avisos que flotan encima del botón fijo "Escanear y entregar producto".
//
// La evidencia se encadena al POD: con red se sube primero y el POD manda el
// `path` que devolvió el backend; sin red la foto cae en la cola offline y el
// POD sale sin `photo_path` (nunca se bloquea la entrega).

final _shipment = shipment(customerName: 'Ana Pérez');

/// Subida directa falsa: devuelve [path] (null = no se pudo, sin red).
class _FakeUploadPodPhoto extends UploadPodPhoto {
  _FakeUploadPodPhoto(super.ref, this.calls, {this.path});

  final List<String> calls;
  final String? path;

  @override
  Future<String?> call({
    required String shipmentId,
    required String filePath,
  }) async {
    calls.add(filePath);
    return path;
  }
}

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
    Future<GpsFix?>? location,
  }) async {
    photoPaths.add(photoPath);
    return SubmitOutcome.sent;
  }
}

class _Harness {
  final enqueued = <Map<String, String>>[];
  final uploaded = <String>[];
  final podPhotoPaths = <String?>[];
  late FakePhotoPicker camera;
  late FakeContinuousScanner scanner;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  List<String?> photos = const [],
  List<String> codes = const [],
  bool enqueueFails = false,
  String? uploadedPath,
}) async {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = _Harness()
    ..camera = FakePhotoPicker(photos)
    ..scanner = FakeContinuousScanner(codes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        // Sin red para el estado de entrega: la pantalla abre igual con la
        // lista de entregados vacía (ver pickup_pod_scan_test.dart).
        storeRepositoryProvider.overrideWithValue(FakeStoreRepository()),
        shipmentUnitsProvider(
          _shipment.id,
        ).overrideWith((ref) async => [unit(unitId: 'unit-1')]),
        photoPickerProvider.overrideWithValue(h.camera.call),
        enqueueDeliveryPhotoProvider.overrideWith(
          (ref) => _FakeEnqueuePhoto(ref, h.enqueued, fail: enqueueFails),
        ),
        uploadPodPhotoProvider.overrideWith(
          (ref) => _FakeUploadPodPhoto(ref, h.uploaded, path: uploadedPath),
        ),
        recordPodProvider.overrideWith(
          (ref) => _FakeRecordPod(ref, h.podPhotoPaths),
        ),
        continuousScannerProvider.overrideWithValue(h.scanner.call),
        labelScannerProvider.overrideWithValue(LabelScanner(null)),
        // El código escaneado representa al producto (Code128): se echo-ea a su
        // propio valor como unit_id.
        labelResolverProvider.overrideWithValue(FakeLabelResolver(echo: true)),
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
    findButtonWithText<FilledButton>('Escanear y entregar producto'),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tomar foto: se pide reducida, se sube y se ve', (tester) async {
    final h = await _pump(
      tester,
      photos: ['/tmp/pod-1.jpg'],
      uploadedPath: 'evidence/pod/abc.jpg',
    );

    await _tapTakePhoto(tester, 'Tomar foto');

    expect(h.camera.requests, [
      (maxWidth: kEvidencePhotoMaxWidth, imageQuality: kEvidencePhotoQuality),
    ]);
    // Subió derecho: nada que encolar (si no, el backend tendría la foto dos
    // veces).
    expect(h.uploaded, ['/tmp/pod-1.jpg']);
    expect(h.enqueued, isEmpty);
    expect(find.text('Foto guardada'), findsOneWidget);
    expect(find.text('Volver a tomar'), findsOneWidget);
    // La vista previa se decodifica acotada (no la foto completa).
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, kPhotoPreviewCacheWidth);
  });

  testWidgets('con red: el POD viaja con el path real de la evidencia', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      photos: ['/tmp/pod-1.jpg'],
      codes: ['unit-1'],
      uploadedPath: 'evidence/pod/abc.jpg',
    );

    await _tapTakePhoto(tester, 'Tomar foto');
    await _deliver(tester);

    expect(h.podPhotoPaths, ['evidence/pod/abc.jpg']);
  });

  testWidgets('sin red: la foto se encola y el POD sale sin photo_path', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      photos: ['/tmp/pod-1.jpg'],
      codes: ['unit-1'],
    );

    await _tapTakePhoto(tester, 'Tomar foto');
    // La entrega no se bloquea por no tener la referencia de la foto.
    await _deliver(tester);

    expect(h.uploaded, ['/tmp/pod-1.jpg']);
    expect(h.enqueued, [
      {'shipmentId': _shipment.id, 'filePath': '/tmp/pod-1.jpg', 'kind': 'pod'},
    ]);
    expect(h.podPhotoPaths, [null]);
    expect(find.text('Foto guardada'), findsOneWidget);
  });

  testWidgets('cancelar la cámara: no sube, no encola ni adjunta foto', (
    tester,
  ) async {
    final h = await _pump(tester, photos: [null], codes: ['unit-1']);

    await _tapTakePhoto(tester, 'Tomar foto');

    expect(h.camera.requests, hasLength(1));
    expect(h.uploaded, isEmpty);
    expect(h.enqueued, isEmpty);
    expect(find.text('Foto guardada'), findsNothing);
    expect(find.byType(Image), findsNothing);

    await _deliver(tester);
    expect(h.podPhotoPaths, [null]);
  });

  testWidgets('volver a tomar sube la nueva foto', (tester) async {
    final h = await _pump(
      tester,
      photos: ['/tmp/a.jpg', '/tmp/b.jpg'],
      uploadedPath: 'evidence/pod/b.jpg',
    );

    await _tapTakePhoto(tester, 'Tomar foto');
    await _tapTakePhoto(tester, 'Volver a tomar');

    expect(h.uploaded, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('si no se pudo guardar la foto avisa y no la adjunta', (
    tester,
  ) async {
    // Sin red (no sube) y la copia a disco de la cola falla: la foto no quedó
    // en ningún lado, hay que repetirla.
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

  testWidgets('producto ajeno: aviso rojo sobre la cámara y sin resumen', (
    tester,
  ) async {
    final h = await _pump(tester, codes: ['unit-de-otro']);

    await _deliver(tester);

    expect(h.scanner.messages, ['No es de este pedido']);
    expect(h.podPhotoPaths, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });
}
