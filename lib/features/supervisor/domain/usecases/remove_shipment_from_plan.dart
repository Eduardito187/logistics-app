import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Command: quita una parada de un plan sin publicar.
class RemoveShipmentFromPlan {
  const RemoveShipmentFromPlan(this._repo);

  final SupervisorRepository _repo;

  Future<void> call(String planId, String shipmentId) =>
      _repo.removeShipmentFromPlan(planId: planId, shipmentId: shipmentId);
}

final removeShipmentFromPlanProvider = Provider<RemoveShipmentFromPlan>(
  (ref) => RemoveShipmentFromPlan(ref.watch(supervisorRepositoryProvider)),
);
