import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/api/models/strategy.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Query: corrida de planificación automática de un día, o `null` si ese día
/// todavía no se planificó (el backend responde 404).
class GetDailyPlanRun {
  const GetDailyPlanRun(this._repo);

  final SupervisorRepository _repo;

  Future<AutoPlanRun?> call(DateTime day) async {
    try {
      return await _repo.getDailyPlanRun(
        date: day,
        strategy: Strategy.optimization,
      );
    } on ApiException catch (error) {
      if (error.status == 404) return null;
      rethrow;
    }
  }
}

final getDailyPlanRunProvider = Provider<GetDailyPlanRun>(
  (ref) => GetDailyPlanRun(ref.watch(supervisorRepositoryProvider)),
);
