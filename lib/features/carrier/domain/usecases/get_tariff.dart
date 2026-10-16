import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/tariff.dart';
import '../../../../core/api/models/vehicle_class.dart';
import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Query: tarifa de un corredor para una clase de vehículo.
class GetTariff {
  const GetTariff(this._repo);

  final CarrierRepository _repo;

  Future<Tariff> call({
    required String carrierId,
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required VehicleClass vehicleClass,
  }) => _repo.getTariff(
    carrierId: carrierId,
    corridorFrom: corridorFrom,
    corridorTo: corridorTo,
    corridorType: corridorType,
    vehicleClass: vehicleClass,
  );
}

final getTariffProvider = Provider<GetTariff>(
  (ref) => GetTariff(ref.watch(carrierRepositoryProvider)),
);
