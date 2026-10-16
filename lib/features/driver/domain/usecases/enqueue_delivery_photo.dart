import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/offline/photo_upload_queue.dart';

/// Command (CQRS) offline-first: encola una foto de evidencia (POD o daños) para
/// subirla idempotentemente cuando haya red. No espera a la subida.
class EnqueueDeliveryPhoto {
  const EnqueueDeliveryPhoto(this._queue);

  final PhotoUploadQueue _queue;

  Future<void> call({
    required String shipmentId,
    required String filePath,
    required String kind,
  }) => _queue.enqueue(shipmentId: shipmentId, filePath: filePath, kind: kind);
}

final enqueueDeliveryPhotoProvider = Provider<EnqueueDeliveryPhoto>(
  (ref) => EnqueueDeliveryPhoto(ref.watch(photoUploadQueueProvider)),
);
