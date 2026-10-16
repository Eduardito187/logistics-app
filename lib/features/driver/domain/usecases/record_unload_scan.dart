import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command (CQRS) offline-first: registra el escaneo de descarga de un bulto en
/// una parada. Pasa por la cola offline (`recordUnloadScan`).
class RecordUnloadScan {
  const RecordUnloadScan(this._queue);

  final OfflineQueue _queue;

  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required double lat,
    required double lng,
    required DateTime occurredAt,
    required String nodeId,
  }) {
    return _queue.submit(
      kind: 'recordUnloadScan',
      payload: UnloadScanRequest(
        shipmentId: shipmentId,
        unitId: unitId,
        lat: lat,
        lng: lng,
        occurredAt: occurredAt,
        nodeId: nodeId,
      ).toJson(),
      label: 'Descarga · $unitId',
      occurredAt: occurredAt,
    );
  }
}

final recordUnloadScanProvider = Provider<RecordUnloadScan>(
  (ref) => RecordUnloadScan(ref.watch(offlineQueueProvider)),
);
