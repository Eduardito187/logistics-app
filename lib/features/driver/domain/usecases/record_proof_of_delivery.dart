import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command (CQRS) offline-first: registra la prueba de entrega (POD) de un
/// bulto. Pasa por la cola offline (`recordProofOfDelivery`). La foto se encola
/// aparte (ver [EnqueueDeliveryPhoto]); acá `photoPath` sólo marca su presencia.
class RecordProofOfDelivery {
  const RecordProofOfDelivery(this._queue);

  final OfflineQueue _queue;

  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required double lat,
    required double lng,
    required DateTime occurredAt,
    required String confirmation,
    String? photoPath,
    required String label,
  }) {
    return _queue.submit(
      kind: 'recordProofOfDelivery',
      payload: ProofOfDeliveryRequest(
        shipmentId: shipmentId,
        unitId: unitId,
        lat: lat,
        lng: lng,
        occurredAt: occurredAt,
        confirmation: confirmation,
        photoPath: photoPath,
      ).toJson(),
      label: label,
      occurredAt: occurredAt,
    );
  }
}

final recordProofOfDeliveryProvider = Provider<RecordProofOfDelivery>(
  (ref) => RecordProofOfDelivery(ref.watch(offlineQueueProvider)),
);
