import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Command: deja las paradas de un plan en el orden de envíos indicado.
class ReorderPlanStops {
  const ReorderPlanStops(this._repo);

  final SupervisorRepository _repo;

  Future<void> call(String planId, List<String> orderedShipmentIds) => _repo
      .reorderPlanStops(planId: planId, orderedShipmentIds: orderedShipmentIds);
}

final reorderPlanStopsProvider = Provider<ReorderPlanStops>(
  (ref) => ReorderPlanStops(ref.watch(supervisorRepositoryProvider)),
);
