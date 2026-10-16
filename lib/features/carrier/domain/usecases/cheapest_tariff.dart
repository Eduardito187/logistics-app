import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/tariff.dart';
import '../../data/repositories/carrier_repository_impl.dart';
import '../repositories/carrier_repository.dart';

/// Query: tarifa más barata disponible para un corredor (entre transportistas).
class CheapestTariff {
  const CheapestTariff(this._repo);

  final CarrierRepository _repo;

  Future<Tariff> call({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
  }) => _repo.cheapestTariff(
    corridorFrom: corridorFrom,
    corridorTo: corridorTo,
    corridorType: corridorType,
  );
}

final cheapestTariffProvider = Provider<CheapestTariff>(
  (ref) => CheapestTariff(ref.watch(carrierRepositoryProvider)),
);
