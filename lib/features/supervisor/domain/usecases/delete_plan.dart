import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Command: borra un plan sin publicar; sus pedidos quedan libres para otro
/// viaje.
class DeletePlan {
  const DeletePlan(this._repo);

  final SupervisorRepository _repo;

  Future<void> call(String planId) => _repo.deletePlan(planId);
}

final deletePlanProvider = Provider<DeletePlan>(
  (ref) => DeletePlan(ref.watch(supervisorRepositoryProvider)),
);
