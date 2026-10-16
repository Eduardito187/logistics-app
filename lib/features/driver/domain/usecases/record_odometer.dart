import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../repositories/fleet_ops_repository.dart';

/// Command (CQRS): registra una lectura de odómetro del vehículo (escritura
/// directa a la red). Propaga `ApiException` ante un error.
class RecordOdometer {
  const RecordOdometer(this._repo);

  final FleetOpsRepository _repo;

  Future<void> call({
    required String vehicleId,
    required int km,
    required RecordOdometerRequestSource source,
    required DateTime readAt,
    String? note,
  }) => _repo.recordOdometer(
    RecordOdometerRequest(
      vehicleId: vehicleId,
      km: km,
      source: source,
      readAt: readAt,
      note: note,
    ),
  );
}

final recordOdometerProvider = Provider<RecordOdometer>(
  (ref) => RecordOdometer(ref.watch(fleetOpsRepositoryProvider)),
);
