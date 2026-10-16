import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../repositories/fleet_ops_repository.dart';

/// Query (CQRS): precio de combustible vigente para un tipo de combustible.
class GetCurrentFuelPrice {
  const GetCurrentFuelPrice(this._repo);

  final FleetOpsRepository _repo;

  Future<FuelPrice> call({required FuelType fuelType}) =>
      _repo.getCurrentFuelPrice(fuelType: fuelType);
}

final getCurrentFuelPriceProvider = Provider<GetCurrentFuelPrice>(
  (ref) => GetCurrentFuelPrice(ref.watch(fleetOpsRepositoryProvider)),
);
