import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command (CQRS) offline-first: registra el escaneo de carga de un bulto al
/// camión. Pasa por la cola offline (`recordLoadScan`): nunca espera a la red.
class RecordLoadScan {
  const RecordLoadScan(this._queue);

  final OfflineQueue _queue;

  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required double lat,
    required double lng,
    required DateTime occurredAt,
  }) {
    return _queue.submit(
      kind: 'recordLoadScan',
      payload: ScanRequest(
        shipmentId: shipmentId,
        unitId: unitId,
        lat: lat,
        lng: lng,
        occurredAt: occurredAt,
      ).toJson(),
      label: 'Carga · $unitId',
      occurredAt: occurredAt,
    );
  }
}

final recordLoadScanProvider = Provider<RecordLoadScan>(
  (ref) => RecordLoadScan(ref.watch(offlineQueueProvider)),
);
