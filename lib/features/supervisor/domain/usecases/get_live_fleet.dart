import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/vehicle_live.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: posiciones en vivo de toda la flota.
class GetLiveFleet {
  const GetLiveFleet(this._repo);

  final SupervisorRepository _repo;

  Future<List<VehicleLive>> call() => _repo.getLiveFleetPositions();
}

final getLiveFleetProvider = Provider<GetLiveFleet>(
  (ref) => GetLiveFleet(ref.watch(supervisorRepositoryProvider)),
);
