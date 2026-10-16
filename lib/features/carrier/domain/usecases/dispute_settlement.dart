import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Command: disputa la liquidación con un motivo (requiere red).
class DisputeSettlement {
  const DisputeSettlement(this._repo);

  final CarrierRepository _repo;

  Future<void> call(String settlementId, String reason) =>
      _repo.disputeSettlement(settlementId, reason);
}

final disputeSettlementProvider = Provider<DisputeSettlement>(
  (ref) => DisputeSettlement(ref.watch(carrierRepositoryProvider)),
);
