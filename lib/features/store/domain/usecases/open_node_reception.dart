import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/open_node_reception_request.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../repositories/store_repository.dart';

/// Command: abre la recepción de un envío en el nodo destino (requiere red).
class OpenNodeReception {
  const OpenNodeReception(this._repo);

  final StoreRepository _repo;

  Future<void> call(OpenNodeReceptionRequest body) =>
      _repo.openNodeReception(body);
}

final openNodeReceptionProvider = Provider<OpenNodeReception>(
  (ref) => OpenNodeReception(ref.watch(storeRepositoryProvider)),
);
