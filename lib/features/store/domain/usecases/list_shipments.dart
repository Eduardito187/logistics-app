import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../repositories/store_repository.dart';

/// Query: envíos visibles para recepción / entrega en mostrador.
class ListShipments {
  const ListShipments(this._repo);

  final StoreRepository _repo;

  Future<List<Shipment>> call() => _repo.listShipments();
}

final listShipmentsProvider = Provider<ListShipments>(
  (ref) => ListShipments(ref.watch(storeRepositoryProvider)),
);
