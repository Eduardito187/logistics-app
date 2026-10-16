import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/proof_of_delivery_request.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command: registra la prueba de entrega al ENTREGAR (offline-first).
///
/// El caso de uso es quien llama a `submit`: la entrega se guarda local con ID
/// idempotente y se sincroniza. El `kind` `'recordProofOfDelivery'` lo resuelve
/// el dispatcher central hacia `api.execution`.
class RecordProofOfDelivery {
  const RecordProofOfDelivery(this._queue);

  final OfflineQueue _queue;

  Future<SubmitOutcome> call({
    required ProofOfDeliveryRequest request,
    required String label,
  }) => _queue.submit(
    kind: 'recordProofOfDelivery',
    payload: request.toJson(),
    label: label,
    occurredAt: request.occurredAt,
  );
}

final recordProofOfDeliveryProvider = Provider<RecordProofOfDelivery>(
  (ref) => RecordProofOfDelivery(ref.watch(offlineQueueProvider)),
);
