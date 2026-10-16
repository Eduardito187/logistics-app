import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node_reception_view.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../repositories/store_repository.dart';

/// Query: estado de la recepción de un envío en un nodo. `null` cuando aún no
/// se abrió.
class GetNodeReception {
  const GetNodeReception(this._repo);

  final StoreRepository _repo;

  Future<NodeReceptionView?> call({
    required String shipmentId,
    required String nodeId,
  }) => _repo.getNodeReception(shipmentId: shipmentId, nodeId: nodeId);
}

final getNodeReceptionProvider = Provider<GetNodeReception>(
  (ref) => GetNodeReception(ref.watch(storeRepositoryProvider)),
);
