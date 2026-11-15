import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/delivery.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';
import 'package:logistics_app/core/labels/label_resolver.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/driver/data/datasources/signature_file_store.dart';
import 'package:logistics_app/features/store/data/repositories/store_repository_impl.dart';
import 'package:logistics_app/features/store/domain/usecases/enqueue_delivery_photo.dart';
import 'package:logistics_app/features/store/domain/usecases/record_pod.dart';
import 'package:logistics_app/features/store/domain/usecases/upload_pod_photo.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/pickup_pod_screen.dart';

import '../../support/button_finders.dart';
import '../../support/fake_label_resolver.dart';
import '../../support/fake_photo_picker.dart';
import '../driver/support/driver_test_support.dart' show FakeLocationService;
import '../driver/support/signature_test_support.dart';
import 'fake_continuous_scanner.dart';
import 'store_fixtures.dart';
import 'store_test_harness.dart';

// Arnés compartido del POD de recojo en tienda (mismo proceso que el chofer):
// escanear productos → firma → foto obligatoria → documento opcional →
// "Registrar entrega". Cámara, escáner, firma, subida y colas son falsos.

/// Subida directa falsa: devuelve [path] (null = no se pudo, sin red).
class FakeUploadPodPhoto extends UploadPodPhoto {
  FakeUploadPodPhoto(super.ref, this.calls, {this.path});

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

/// Cola de fotos/evidencia falsa: registra lo encolado o falla si [fail].
class FakeEnqueuePhoto extends EnqueueDeliveryPhoto {
  FakeEnqueuePhoto(super.ref, this.calls, {this.fail = false});

  final List<Map<String, Object?>> calls;
  final bool fail;

  @override
  Future<void> call({
    required String shipmentId,
    required String filePath,
    required String kind,
    Map<String, Object?>? clientSnapshot,
  }) async {
    if (fail) throw Exception('disco lleno');
    calls.add({
      'shipmentId': shipmentId,
      'filePath': filePath,
      'kind': kind,
      'hasSnapshot': clientSnapshot != null,
    });
  }
}

/// Caso de uso falso: registra cada POD y devuelve el desenlace de [outcomeFor]
/// (por producto) o [outcome].
class FakeRecordPod extends RecordPod {
  FakeRecordPod(super.ref, this.calls, this.outcome, this.outcomeFor);

  final List<Map<String, String?>> calls;
  final SubmitOutcome outcome;
  final SubmitOutcome Function(String unitId)? outcomeFor;

  @override
  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required String confirmation,
    required String customerName,
    String? photoPath,
    Future<GpsFix?>? location,
  }) async {
    calls.add({
      'shipmentId': shipmentId,
      'unitId': unitId,
      'confirmation': confirmation,
      'customerName': customerName,
      'photoPath': photoPath,
    });
    return outcomeFor?.call(unitId) ?? outcome;
  }
}

class PickupHarness {
  final pods = <Map<String, String?>>[];
  final enqueued = <Map<String, Object?>>[];
  final uploaded = <String>[];
  final signatures = FakeSignatureFileStore();
  late FakePhotoPicker camera;
  late FakeContinuousScanner products;

  List<String?> get podUnitIds => [for (final c in pods) c['unitId']];
}

/// Monta el POD de recojo de [shipment] con todo falso.
///
/// - [photos]: lo que devuelve la cámara en cada toma (foto y documento).
/// - [signs]: si `false`, el cliente cancela la firma.
Future<PickupHarness> pumpPickupPod(
  WidgetTester tester, {
  required Shipment shipment,
  List<String> products = const [],
  List<List<String>>? productSessions,
  List<UnitTracking>? units,
  List<String?> photos = const ['/tmp/pod.jpg'],
  bool signs = true,
  LabelScanner? labelScanner,
  SubmitOutcome outcome = SubmitOutcome.sent,
  SubmitOutcome Function(String unitId)? outcomeFor,
  String? uploadedPath,
  bool enqueueFails = false,
  Future<Delivery> Function(String shipmentId)? onGetDeliveryState,
}) async {
  // Superficie alta: la lista es perezosa y en 800x600 deja botones fuera.
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = PickupHarness()
    ..camera = FakePhotoPicker(photos)
    ..products = productSessions != null
        ? FakeContinuousScanner.sessions(productSessions)
        : FakeContinuousScanner(products);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        // Entregas que el servidor ya tiene confirmadas: siembran la lista de
        // entregados al abrir. Sin `onGetDeliveryState` el repositorio falso
        // falla y la pantalla abre igual (offline-first).
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(onGetDeliveryState: onGetDeliveryState),
        ),
        shipmentUnitsProvider(shipment.id).overrideWith(
          (ref) async =>
              units ?? [unit(unitId: 'unit-1'), unit(unitId: 'unit-2')],
        ),
        continuousScannerProvider.overrideWithValue(h.products.call),
        labelScannerProvider.overrideWithValue(
          labelScanner ?? LabelScanner(null),
        ),
        // El código escaneado representa al producto (Code128): se resuelve con
        // su propio valor como unit_id (el backend real lo mapea).
        labelResolverProvider.overrideWithValue(FakeLabelResolver(echo: true)),
        // GPS falso: el registro pide la posición y, sin esto, esperaría al
        // plugin real (que en los tests nunca responde).
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        photoPickerProvider.overrideWithValue(h.camera.call),
        pickupSignatureCaptureProvider.overrideWithValue(
          (_) async => signs ? kTinyPng : null,
        ),
        signatureFileStoreProvider.overrideWithValue(h.signatures),
        uploadPodPhotoProvider.overrideWith(
          (ref) => FakeUploadPodPhoto(ref, h.uploaded, path: uploadedPath),
        ),
        enqueueDeliveryPhotoProvider.overrideWith(
          (ref) => FakeEnqueuePhoto(ref, h.enqueued, fail: enqueueFails),
        ),
        recordPodProvider.overrideWith(
          (ref) => FakeRecordPod(ref, h.pods, outcome, outcomeFor),
        ),
      ],
      child: MaterialApp(home: PickupPodScreen(shipment: shipment)),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

/// Abre la cámara de productos (una sesión del escáner continuo).
Future<void> tapScanProducts(WidgetTester tester) async {
  await tester.tap(findButtonWithText<FilledButton>('Escanear productos'));
  await tester.pumpAndSettle();
}

Future<void> tapSign(WidgetTester tester) async {
  await tester.tap(findButtonWithText<OutlinedButton>('Firma del cliente'));
  await tester.pumpAndSettle();
}

Future<void> tapTakePhoto(
  WidgetTester tester, [
  String label = 'Tomar foto',
]) async {
  await tester.tap(findButtonWithText<OutlinedButton>(label));
  await tester.pumpAndSettle();
}

Future<void> tapTakeDocument(WidgetTester tester) async {
  await tester.tap(findButtonWithText<OutlinedButton>('Foto del documento'));
  await tester.pumpAndSettle();
}

Future<void> tapRegister(WidgetTester tester) async {
  await tester.tap(findButtonWithText<FilledButton>('Registrar entrega'));
  await tester.pumpAndSettle();
}

/// Recorre el flujo completo: escanear, firmar, foto y registrar.
Future<void> deliverAll(WidgetTester tester) async {
  await tapScanProducts(tester);
  await tapSign(tester);
  await tapTakePhoto(tester);
  await tapRegister(tester);
}
