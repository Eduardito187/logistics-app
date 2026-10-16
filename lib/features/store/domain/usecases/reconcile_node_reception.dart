import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/reconcile_node_reception_request.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../repositories/store_repository.dart';

/// Command: concilia y cierra la recepción (requiere red).
class ReconcileNodeReception {
  const ReconcileNodeReception(this._repo);

  final StoreRepository _repo;

  Future<void> call(ReconcileNodeReceptionRequest body) =>
      _repo.reconcileNodeReception(body);
}

final reconcileNodeReceptionProvider = Provider<ReconcileNodeReception>(
  (ref) => ReconcileNodeReception(ref.watch(storeRepositoryProvider)),
);
