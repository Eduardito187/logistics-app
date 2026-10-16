import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fleet_ops_repository_impl.dart';
import '../entities/due_maintenance_item.dart';
import '../repositories/fleet_ops_repository.dart';

/// Query (CQRS): mantenimiento preventivo por vencer o vencido (más urgente
/// primero).
class ListDueMaintenance {
  const ListDueMaintenance(this._repo);

  final FleetOpsRepository _repo;

  Future<List<DueMaintenanceItem>> call() => _repo.listDueMaintenance();
}

final listDueMaintenanceProvider = Provider<ListDueMaintenance>(
  (ref) => ListDueMaintenance(ref.watch(fleetOpsRepositoryProvider)),
);
