import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/driver/presentation/failed_delivery_screen.dart';
import 'package:logistics_app/features/driver/presentation/pod_screen.dart';

import '../../../support/fake_code_scanner.dart';
import '../../../support/fake_photo_picker.dart';
import '../support/driver_test_support.dart';
import '../support/signature_test_support.dart';

// Flujos con foto de evidencia (POD y entrega fallida). La cámara se inyecta
// con photoPickerProvider (FakePhotoPicker) y la cola de fotos con un doble que
// registra lo encolado: tomar foto → se adjunta y encola con su ruta; cancelar
// → sin foto; siempre se pide la foto reducida (1600 px, calidad 70).

/// Cola de fotos falsa: registra lo encolado sin tocar disco ni red.
class _FakePhotoUploadQueue implements PhotoUploadQueue {
  final List<({String shipmentId, String filePath, String kind})> enqueued = [];

  @override
  Future<void> enqueue({
    required String shipmentId,
    required String filePath,
    required String kind,
  }) async {
    enqueued.add((shipmentId: shipmentId, filePath: filePath, kind: kind));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Object> _overrides({
  required FakePhotoPicker picker,
  required _FakePhotoUploadQueue photos,
  required FakeOfflineQueue queue,
  List<String?> scans = const [],
  FakeSignatureFileStore? signatures,
}) => [
  photoPickerProvider.overrideWithValue(picker.call),
  photoUploadQueueProvider.overrideWithValue(photos),
  offlineQueueProvider.overrideWithValue(queue),
  codeScannerProvider.overrideWithValue(FakeCodeScanner(scans).call),
  labelScannerProvider.overrideWithValue(vectorLabelScanner()),
  locationServiceProvider.overrideWithValue(FakeLocationService()),
  ...signatureOverrides(signatures ?? FakeSignatureFileStore()),
];

/// Vista previa de la foto adjunta (Image.file con su ruta).
Finder _preview(String path) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is ResizeImage &&
      ((w.image as ResizeImage).imageProvider as FileImage).file.path == path,
);

void main() {
  group('POD', () {
    testWidgets('tomar foto: se pide reducida, se adjunta y se encola', (
      tester,
    ) async {
      final picker = FakePhotoPicker(['/tmp/pod.jpg']);
      final photos = _FakePhotoUploadQueue();
      final queue = FakeOfflineQueue(SubmitOutcome.sent);
      await pumpPushed(
        tester,
        child: PodScreen(stop: buildStop(shipmentId: 'ship-7')),
        overrides: _overrides(
          picker: picker,
          photos: photos,
          queue: queue,
          scans: [validLabelQr()],
        ),
        tall: true,
      );

      await tester.tap(find.text('Tomar foto'));
      await tester.pump();

      expect(picker.requests, [
        (maxWidth: kEvidencePhotoMaxWidth, imageQuality: kEvidencePhotoQuality),
      ]);
      expect(_preview('/tmp/pod.jpg'), findsOneWidget);
      // La vista previa se decodifica acotada (no a la resolución de cámara).
      final image = tester.widget<Image>(_preview('/tmp/pod.jpg'));
      expect((image.image as ResizeImage).width, 800);
      expect(find.text('Volver a tomar'), findsOneWidget);

      await tester.tap(find.text('Escanear bulto'));
      await tester.pumpAndSettle();
      await signOnPad(tester);
      await tester.tap(find.text('Registrar entrega'));
      await tester.pumpAndSettle();

      // Foto de la entrega + imagen de la firma (como evidencia `pod`).
      expect(photos.enqueued, [
        (shipmentId: 'ship-7', filePath: '/tmp/pod.jpg', kind: 'pod'),
        (shipmentId: 'ship-7', filePath: '/tmp/firma.png', kind: 'pod'),
      ]);
      expect(queue.submissions.single['photo_path'], 'pendiente');
      expect(find.byType(PodScreen), findsNothing);
    });

    testWidgets('cancelar la cámara: sin foto no se puede registrar el POD', (
      tester,
    ) async {
      final picker = FakePhotoPicker([null]);
      final photos = _FakePhotoUploadQueue();
      final queue = FakeOfflineQueue(SubmitOutcome.sent);
      await pumpPushed(
        tester,
        child: PodScreen(stop: buildStop()),
        overrides: _overrides(
          picker: picker,
          photos: photos,
          queue: queue,
          scans: [validLabelQr()],
        ),
        tall: true,
      );

      await tester.tap(find.text('Tomar foto'));
      await tester.pump();

      expect(picker.requests, hasLength(1));
      expect(find.byType(Image), findsNothing);
      expect(find.text('Tomar foto'), findsOneWidget);

      await tester.tap(find.text('Escanear bulto'));
      await tester.pumpAndSettle();
      await signOnPad(tester);
      // La foto de la entrega es obligatoria: sin ella no se registra.
      final register = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Registrar entrega'),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        ),
      );
      expect(register.onPressed, isNull);
      expect(photos.enqueued, isEmpty);
      expect(queue.submissions, isEmpty);
    });

    testWidgets('volver a tomar reemplaza la foto adjunta', (tester) async {
      final picker = FakePhotoPicker(['/tmp/a.jpg', '/tmp/b.jpg']);
      await pumpScoped(
        tester,
        child: PodScreen(stop: buildStop()),
        overrides: _overrides(
          picker: picker,
          photos: _FakePhotoUploadQueue(),
          queue: FakeOfflineQueue(SubmitOutcome.sent),
        ),
        tall: true,
      );

      await tester.tap(find.text('Tomar foto'));
      await tester.pump();
      await tester.tap(find.text('Volver a tomar'));
      await tester.pump();

      expect(picker.requests, hasLength(2));
      expect(_preview('/tmp/a.jpg'), findsNothing);
      expect(_preview('/tmp/b.jpg'), findsOneWidget);
    });

    testWidgets(
      'firma: guarda el PNG, lo encola como evidencia y descarta el original',
      (tester) async {
        final photos = _FakePhotoUploadQueue();
        final signatures = FakeSignatureFileStore(path: '/docs/firma-1.png');
        final queue = FakeOfflineQueue(SubmitOutcome.sent);
        await pumpPushed(
          tester,
          child: PodScreen(stop: buildStop(shipmentId: 'ship-3')),
          overrides: _overrides(
            picker: FakePhotoPicker(['/tmp/pod.jpg']),
            photos: photos,
            queue: queue,
            scans: [validLabelQr()],
            signatures: signatures,
          ),
          tall: true,
        );

        await tester.tap(find.text('Escanear bulto'));
        await tester.pumpAndSettle();
        await signOnPad(tester);
        // Firmado pero sin foto: la foto sigue siendo obligatoria.
        final register = find.ancestor(
          of: find.text('Registrar entrega'),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        );
        expect(tester.widget<FilledButton>(register).onPressed, isNull);
        // Hasta registrar no se escribe nada en disco.
        expect(signatures.saved, isEmpty);

        await tester.tap(find.text('Tomar foto'));
        await tester.pump();
        await tester.tap(find.text('Registrar entrega'));
        await tester.pumpAndSettle();

        expect(signatures.saved.single, kTinyPng);
        expect(photos.enqueued.last, (
          shipmentId: 'ship-3',
          filePath: '/docs/firma-1.png',
          kind: kSignatureEvidenceKind,
        ));
        expect(signatures.discarded, ['/docs/firma-1.png']);
        expect(queue.submissions.single['confirmation'], 'FIRMA_DIGITAL');
      },
    );

    testWidgets('con QR del cliente no se encola ninguna firma', (
      tester,
    ) async {
      final photos = _FakePhotoUploadQueue();
      final signatures = FakeSignatureFileStore();
      await pumpPushed(
        tester,
        child: PodScreen(stop: buildStop(shipmentId: 'ship-4')),
        overrides: _overrides(
          picker: FakePhotoPicker(['/tmp/pod.jpg']),
          photos: photos,
          queue: FakeOfflineQueue(SubmitOutcome.sent),
          scans: [validLabelQr(), 'CONF-9'],
          signatures: signatures,
        ),
        tall: true,
      );

      await tester.tap(find.text('Escanear bulto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escanear QR del cliente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tomar foto'));
      await tester.pump();
      await tester.tap(find.text('Registrar entrega'));
      await tester.pumpAndSettle();

      expect(photos.enqueued, [
        (shipmentId: 'ship-4', filePath: '/tmp/pod.jpg', kind: 'pod'),
      ]);
      expect(signatures.saved, isEmpty);
    });
  });

  group('Entrega fallida', () {
    testWidgets('tomar foto: se pide reducida y se encola como daño', (
      tester,
    ) async {
      final picker = FakePhotoPicker(['/tmp/damage.jpg']);
      final photos = _FakePhotoUploadQueue();
      final queue = FakeOfflineQueue(SubmitOutcome.queued);
      await pumpPushed(
        tester,
        child: FailedDeliveryScreen(stop: buildStop(shipmentId: 'ship-5')),
        overrides: _overrides(
          picker: picker,
          photos: photos,
          queue: queue,
          scans: [validLabelQr()],
        ),
        tall: true,
      );

      await tester.tap(find.text('Tomar foto'));
      await tester.pump();

      expect(picker.requests.single.maxWidth, kEvidencePhotoMaxWidth);
      expect(picker.requests.single.imageQuality, kEvidencePhotoQuality);
      expect(_preview('/tmp/damage.jpg'), findsOneWidget);

      await tester.tap(find.text('Escanear bulto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar entrega fallida'));
      await tester.pumpAndSettle();

      expect(photos.enqueued, [
        (shipmentId: 'ship-5', filePath: '/tmp/damage.jpg', kind: 'damage'),
      ]);
      expect(queue.lastKind, 'recordFailedDelivery');
      expect(find.byType(FailedDeliveryScreen), findsNothing);
    });

    testWidgets('cancelar la cámara: se registra sin foto', (tester) async {
      final picker = FakePhotoPicker([null]);
      final photos = _FakePhotoUploadQueue();
      final queue = FakeOfflineQueue(SubmitOutcome.sent);
      await pumpPushed(
        tester,
        child: FailedDeliveryScreen(stop: buildStop()),
        overrides: _overrides(
          picker: picker,
          photos: photos,
          queue: queue,
          scans: [validLabelQr()],
        ),
        tall: true,
      );

      await tester.tap(find.text('Tomar foto'));
      await tester.pump();
      expect(find.byType(Image), findsNothing);

      await tester.tap(find.text('Escanear bulto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar entrega fallida'));
      await tester.pumpAndSettle();

      expect(photos.enqueued, isEmpty);
      expect(queue.submissions, hasLength(1));
    });
  });
}
