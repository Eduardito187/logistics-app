import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Command: marca la liquidación como pagada con una referencia (requiere red).
class PaySettlement {
  const PaySettlement(this._repo);

  final CarrierRepository _repo;

  Future<void> call(String settlementId, String paymentReference) =>
      _repo.paySettlement(settlementId, paymentReference);
}

final paySettlementProvider = Provider<PaySettlement>(
  (ref) => PaySettlement(ref.watch(carrierRepositoryProvider)),
);
