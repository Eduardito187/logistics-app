import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/fleet_repository_impl.dart';
import '../repositories/fleet_repository.dart';

/// Query (CQRS): choferes activos (para firmar el checklist pre-salida).
class ListActiveDrivers {
  const ListActiveDrivers(this._repo);

  final FleetRepository _repo;

  Future<List<Driver>> call() => _repo.listActiveDrivers();
}

final listActiveDriversProvider = Provider<ListActiveDrivers>(
  (ref) => ListActiveDrivers(ref.watch(fleetRepositoryProvider)),
);
