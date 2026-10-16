import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../repositories/store_repository.dart';

/// Query: nodos activos de la red (candidatos a tienda/nodo de recepción).
class ListNodes {
  const ListNodes(this._repo);

  final StoreRepository _repo;

  Future<List<Node>> call() => _repo.listNodes();
}

final listNodesProvider = Provider<ListNodes>(
  (ref) => ListNodes(ref.watch(storeRepositoryProvider)),
);
