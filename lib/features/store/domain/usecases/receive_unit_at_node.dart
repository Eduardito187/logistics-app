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
    Future<GpsFix?>? location,
  }) async {
    // [location]: fix pedido por la pantalla en paralelo con la cámara (ya
    // suele estar listo al leer el código). Sin él se pide acá.
    final fix = await _fix(location);
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

  Future<GpsFix?> _fix(Future<GpsFix?>? location) async {
    try {
      return await (location ?? _ref.read(locationServiceProvider).current());
    } on Object {
      // Sin GPS el registro sigue igual (lat/lng en cero): nunca se traba.
      return null;
    }
  }
}

final receiveUnitAtNodeProvider = Provider<ReceiveUnitAtNode>(
  ReceiveUnitAtNode.new,
);
