import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/settlement.dart';
import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Query: detalle de una liquidación.
class GetSettlement {
  const GetSettlement(this._repo);

  final CarrierRepository _repo;

  Future<Settlement> call(String settlementId) =>
      _repo.getSettlement(settlementId);
}

final getSettlementProvider = Provider<GetSettlement>(
  (ref) => GetSettlement(ref.watch(carrierRepositoryProvider)),
);
