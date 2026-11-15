import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Command: agrega un envío a este camión (o lo mueve desde otro plan).
class AssignShipmentToPlan {
  const AssignShipmentToPlan(this._repo);

  final SupervisorRepository _repo;

  Future<void> call(String planId, String shipmentId) =>
      _repo.assignShipmentToPlan(planId: planId, shipmentId: shipmentId);
}

final assignShipmentToPlanProvider = Provider<AssignShipmentToPlan>(
  (ref) => AssignShipmentToPlan(ref.watch(supervisorRepositoryProvider)),
);
