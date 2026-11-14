import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/media/photo_picker.dart';
import 'package:logistics_app/core/widgets/app_snack.dart';
import 'package:logistics_app/features/store/presentation/pickup_pod_screen.dart';

import '../pickup_pod_support.dart';
import '../store_fixtures.dart';

// Recojo en tienda: foto de evidencia (cámara falsa vía `photoPickerProvider`)
// y avisos que flotan encima del botón fijo del pie.
//
// La evidencia se encadena al POD: con red se sube primero y el POD manda el
// `path` que devolvió el backend; sin red la foto cae en la cola offline y el
// POD sale sin `photo_path` (nunca se bloquea la entrega).

final _shipment = shipment(customerName: 'Ana Pérez');
final _oneUnit = [unit(unitId: 'unit-1')];

Map<String, Object?> _podPhoto(String path) => {
  'shipmentId': _shipment.id,
  'filePath': path,
  'kind': 'pod',
  'hasSnapshot': false,
};

void main() {
  testWidgets('tomar foto: se pide reducida, se sube y se ve', (tester) async {
    final h = await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: _oneUnit,
      photos: ['/tmp/pod-1.jpg'],
      uploadedPath: 'evidence/pod/abc.jpg',
    );

    await tapTakePhoto(tester);

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
    final h = await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: _oneUnit,
      products: ['unit-1'],
      uploadedPath: 'evidence/pod/abc.jpg',
    );

    await deliverAll(tester);

    expect(h.pods.single['photoPath'], 'evidence/pod/abc.jpg');
  });

  testWidgets('sin red: la foto se encola y el POD sale sin photo_path', (
    tester,
  ) async {
    final h = await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: _oneUnit,
      products: ['unit-1'],
      photos: ['/tmp/pod-1.jpg'],
    );

    // La entrega no se bloquea por no tener la referencia de la foto.
    await deliverAll(tester);

    expect(h.uploaded, ['/tmp/pod-1.jpg']);
    expect(h.enqueued, contains(_podPhoto('/tmp/pod-1.jpg')));
    expect(h.pods.single['photoPath'], isNull);
  });

  testWidgets('cancelar la cámara: no sube ni encola, y no deja registrar', (
    tester,
  ) async {
    final h = await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: _oneUnit,
      products: ['unit-1'],
      photos: [null],
    );

    await tapScanProducts(tester);
    await tapSign(tester);
    await tapTakePhoto(tester);

    expect(h.camera.requests, hasLength(1));
    expect(h.uploaded, isEmpty);
    expect(h.enqueued, isEmpty);
    expect(find.text('Foto guardada'), findsNothing);
    // La foto de entrega es OBLIGATORIA: sin ella no se registra.
    expect(find.text('Falta la foto de entrega.'), findsOneWidget);
    expect(h.pods, isEmpty);
  });

  testWidgets('volver a tomar sube la nueva foto', (tester) async {
    final h = await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: _oneUnit,
      photos: ['/tmp/a.jpg', '/tmp/b.jpg'],
      uploadedPath: 'evidence/pod/b.jpg',
    );

    await tapTakePhoto(tester);
    await tapTakePhoto(tester, 'Volver a tomar');

    expect(h.uploaded, ['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('si no se pudo guardar la foto avisa y no la adjunta', (
    tester,
  ) async {
    // Sin red (no sube) y la copia a disco de la cola falla: la foto no quedó
    // en ningún lado, hay que repetirla.
    final h = await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: _oneUnit,
      photos: ['/tmp/a.jpg'],
      enqueueFails: true,
    );

    await tapTakePhoto(tester);

    expect(
      find.text('No se pudo guardar la foto. Intentá de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Foto guardada'), findsNothing);
    expect(h.enqueued, isEmpty);
  });

  testWidgets('el aviso de registro flota encima del botón fijo del pie', (
    tester,
  ) async {
    await pumpPickupPod(
      tester,
      shipment: _shipment,
      units: _oneUnit,
      products: ['unit-1'],
    );

    await deliverAll(tester);

    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(
      snack.margin,
      const EdgeInsets.fromLTRB(16, 0, 16, kBottomActionClearance),
    );
  });
}
