import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../repositories/fleet_ops_repository.dart';

/// Command (CQRS): registra una carga de combustible del vehículo (escritura
/// directa a la red). Propaga `ApiException` ante un error.
class RecordRefuel {
  const RecordRefuel(this._repo);

  final FleetOpsRepository _repo;

  Future<AcceptedEnvelope> call({
    required String vehicleId,
    required FuelType fuelType,
    required double liters,
    required int pricePerLiterCents,
    required String currency,
    required bool fullTank,
    required DateTime refueledAt,
    int? odometerKm,
    String? note,
  }) => _repo.recordRefuel(
    RecordRefuelRequest(
      vehicleId: vehicleId,
      fuelType: fuelType,
      liters: liters,
      pricePerLiterCents: pricePerLiterCents,
      currency: currency,
      fullTank: fullTank,
      refueledAt: refueledAt,
      odometerKm: odometerKm,
      note: note,
    ),
  );
}

final recordRefuelProvider = Provider<RecordRefuel>(
  (ref) => RecordRefuel(ref.watch(fleetOpsRepositoryProvider)),
);
