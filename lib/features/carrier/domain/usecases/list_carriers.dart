import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/carrier.dart';
import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Query: transportistas activos para elegir el propio.
class ListCarriers {
  const ListCarriers(this._repo);

  final CarrierRepository _repo;

  Future<List<Carrier>> call() => _repo.listCarriers();
}

final listCarriersProvider = Provider<ListCarriers>(
  (ref) => ListCarriers(ref.watch(carrierRepositoryProvider)),
);
