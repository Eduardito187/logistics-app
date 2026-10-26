import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: placa de cada camión de la flota, por id de vehículo.
class GetVehiclePlates {
  const GetVehiclePlates(this._repo);

  final SupervisorRepository _repo;

  Future<Map<String, String>> call() => _repo.getVehiclePlates();
}

final getVehiclePlatesProvider = Provider<GetVehiclePlates>(
  (ref) => GetVehiclePlates(ref.watch(supervisorRepositoryProvider)),
);
