import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/data7.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: ETA por parada de un plan.
class GetPlanEta {
  const GetPlanEta(this._repo);

  final SupervisorRepository _repo;

  Future<Data7> call(String planId) => _repo.getPlanEta(planId);
}

final getPlanEtaProvider = Provider<GetPlanEta>(
  (ref) => GetPlanEta(ref.watch(supervisorRepositoryProvider)),
);
