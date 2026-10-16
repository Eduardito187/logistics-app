import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_repository_impl.dart';
import '../repositories/fleet_repository.dart';

/// Query (CQRS): asignación (vehículo + tripulación) del chofer autenticado
/// para una fecha. El chofer no elige: se le asigna.
class GetMyCrew {
  const GetMyCrew(this._repo);

  final FleetRepository _repo;

  Future<MyCrew> call(DateTime date) => _repo.getMyCrew(date);
}

final getMyCrewProvider = Provider<GetMyCrew>(
  (ref) => GetMyCrew(ref.watch(fleetRepositoryProvider)),
);
