import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/get_plan_eta_data.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: ETA por parada de un plan.
class GetPlanEta {
  const GetPlanEta(this._repo);

  final SupervisorRepository _repo;

  Future<GetPlanEtaData> call(String planId) => _repo.getPlanEta(planId);
}

final getPlanEtaProvider = Provider<GetPlanEta>(
  (ref) => GetPlanEta(ref.watch(supervisorRepositoryProvider)),
);
