import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Command: publica un plan (queda visible para el preparador y el chofer).
class PublishPlan {
  const PublishPlan(this._repo);

  final SupervisorRepository _repo;

  Future<void> call(String planId) => _repo.publishPlan(planId);
}

final publishPlanProvider = Provider<PublishPlan>(
  (ref) => PublishPlan(ref.watch(supervisorRepositoryProvider)),
);
