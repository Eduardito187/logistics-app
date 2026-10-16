import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Command: aprueba la liquidación (requiere red).
class ApproveSettlement {
  const ApproveSettlement(this._repo);

  final CarrierRepository _repo;

  Future<void> call(String settlementId) =>
      _repo.approveSettlement(settlementId);
}

final approveSettlementProvider = Provider<ApproveSettlement>(
  (ref) => ApproveSettlement(ref.watch(carrierRepositoryProvider)),
);
