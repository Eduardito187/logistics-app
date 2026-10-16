import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/scan_request.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command: registra un escaneo de carga al RECOGER (offline-first).
///
/// El caso de uso es quien llama a `submit`: el escaneo nunca espera a la red,
/// se guarda local con ID idempotente y se sincroniza. El `kind`
/// `'recordLoadScan'` lo resuelve el dispatcher central hacia `api.execution`.
class RecordLoadScan {
  const RecordLoadScan(this._queue);

  final OfflineQueue _queue;

  Future<SubmitOutcome> call({
    required ScanRequest request,
    required String label,
  }) => _queue.submit(
    kind: 'recordLoadScan',
    payload: request.toJson(),
    label: label,
    occurredAt: request.occurredAt,
  );
}

final recordLoadScanProvider = Provider<RecordLoadScan>(
  (ref) => RecordLoadScan(ref.watch(offlineQueueProvider)),
);
