import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/settlement.dart';
import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Query: liquidaciones del transportista indicado.
class ListSettlements {
  const ListSettlements(this._repo);

  final CarrierRepository _repo;

  Future<List<Settlement>> call(String carrierId) =>
      _repo.listSettlements(carrierId);
}

final listSettlementsProvider = Provider<ListSettlements>(
  (ref) => ListSettlements(ref.watch(carrierRepositoryProvider)),
);
