import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/unit_tracking.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../repositories/store_repository.dart';

/// Query: productos esperados de un envío (uno por unidad física).
class GetShipmentUnits {
  const GetShipmentUnits(this._repo);

  final StoreRepository _repo;

  Future<List<UnitTracking>> call(String shipmentId) =>
      _repo.getShipmentUnits(shipmentId);
}

final getShipmentUnitsProvider = Provider<GetShipmentUnits>(
  (ref) => GetShipmentUnits(ref.watch(storeRepositoryProvider)),
);
