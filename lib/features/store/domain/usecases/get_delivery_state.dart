import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/delivery.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../repositories/store_repository.dart';

/// Query: estado de la entrega de un envío con sus escaneos (solo lectura).
class GetDeliveryState {
  const GetDeliveryState(this._repo);

  final StoreRepository _repo;

  Future<Delivery> call(String shipmentId) =>
      _repo.getDeliveryState(shipmentId);
}

final getDeliveryStateProvider = Provider<GetDeliveryState>(
  (ref) => GetDeliveryState(ref.watch(storeRepositoryProvider)),
);
