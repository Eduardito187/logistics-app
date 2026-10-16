import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command (CQRS) offline-first: registra una entrega fallida con su motivo.
/// Pasa por la cola offline (`recordFailedDelivery`). La foto de daños se encola
/// aparte (ver [EnqueueDeliveryPhoto]).
class RecordFailedDelivery {
  const RecordFailedDelivery(this._queue);

  final OfflineQueue _queue;

  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required double lat,
    required double lng,
    required DateTime occurredAt,
    required FailureReason reason,
    required String label,
  }) {
    return _queue.submit(
      kind: 'recordFailedDelivery',
      payload: FailedDeliveryRequest(
        shipmentId: shipmentId,
        unitId: unitId,
        lat: lat,
        lng: lng,
        occurredAt: occurredAt,
        reason: reason,
      ).toJson(),
      label: label,
      occurredAt: occurredAt,
    );
  }
}

final recordFailedDeliveryProvider = Provider<RecordFailedDelivery>(
  (ref) => RecordFailedDelivery(ref.watch(offlineQueueProvider)),
);
