import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/plan.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: detalle de un plan con su secuencia de paradas.
class GetPlan {
  const GetPlan(this._repo);

  final SupervisorRepository _repo;

  Future<Plan> call(String planId) => _repo.getPlan(planId);
}

final getPlanProvider = Provider<GetPlan>(
  (ref) => GetPlan(ref.watch(supervisorRepositoryProvider)),
);
