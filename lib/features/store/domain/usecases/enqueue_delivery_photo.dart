import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/photo_upload_queue.dart';

/// Command: encola la foto de evidencia del POD. Parte del flujo de entrega:
/// la subida multipart es offline-first (se copia a disco y se reintenta), por
/// eso pasa por `photoUploadQueueProvider` y no bloquea la entrega.
class EnqueueDeliveryPhoto {
  const EnqueueDeliveryPhoto(this._ref);

  final Ref _ref;

  Future<void> call({
    required String shipmentId,
    required String filePath,
    required String kind,
  }) => _ref
      .read(photoUploadQueueProvider)
      .enqueue(shipmentId: shipmentId, filePath: filePath, kind: kind);
}

final enqueueDeliveryPhotoProvider = Provider<EnqueueDeliveryPhoto>(
  EnqueueDeliveryPhoto.new,
);
