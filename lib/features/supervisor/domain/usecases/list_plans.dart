import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/plan.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: planes del día indicado (uno por camión).
class ListPlans {
  const ListPlans(this._repo);

  final SupervisorRepository _repo;

  Future<List<Plan>> call(DateTime date) => _repo.listPlansByDate(date);
}

final listPlansProvider = Provider<ListPlans>(
  (ref) => ListPlans(ref.watch(supervisorRepositoryProvider)),
);
