import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/receive_unit_at_node_request.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command: recibe un bulto en el nodo. Escritura de terreno: por la regla
/// offline-first pasa por `offlineQueueProvider.submit`, nunca espera a la red.
/// El dispatcher de la cola es quien luego hace la llamada real al backend.
class ReceiveUnitAtNode {
  const ReceiveUnitAtNode(this._ref);

  final Ref _ref;

  Future<SubmitOutcome> call({
    required String shipmentId,
    required String unitId,
    required String destinationNodeId,
    required String customerName,
  }) async {
    final fix = await _ref.read(locationServiceProvider).current();
    return _ref
        .read(offlineQueueProvider)
        .submit(
          kind: 'receiveUnitAtNode',
          payload: ReceiveUnitAtNodeRequest(
            shipmentId: shipmentId,
            unitId: unitId,
            lat: fix?.lat ?? 0,
            lng: fix?.lng ?? 0,
            occurredAt: DateTime.now(),
            destinationNodeId: destinationNodeId,
          ).toJson(),
          label: 'Recepción · $customerName',
        );
  }
}

final receiveUnitAtNodeProvider = Provider<ReceiveUnitAtNode>(
  ReceiveUnitAtNode.new,
);
