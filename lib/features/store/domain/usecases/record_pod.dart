import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/proof_of_delivery_request.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command: registra la prueba de entrega (POD) de un bulto en mostrador.
/// Escritura de terreno: por la regla offline-first pasa por
/// `offlineQueueProvider.submit` y nunca espera a la red. La foto de evidencia
/// se encola aparte con [EnqueueDeliveryPhoto].
class RecordPod {
  const RecordPod(this._ref);

  final Ref _ref;

  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required String confirmation,
    required String customerName,
    String? photoPath,
  }) async {
    final fix = await _ref.read(locationServiceProvider).current();
    return _ref
        .read(offlineQueueProvider)
        .submit(
          kind: 'recordProofOfDelivery',
          payload: ProofOfDeliveryRequest(
            shipmentId: shipmentId,
            unitId: unitId,
            lat: fix?.lat ?? 0,
            lng: fix?.lng ?? 0,
            occurredAt: DateTime.now(),
            confirmation: confirmation,
            photoPath: photoPath,
          ).toJson(),
          label: 'Entrega · $customerName',
        );
  }
}

final recordPodProvider = Provider<RecordPod>(RecordPod.new);
