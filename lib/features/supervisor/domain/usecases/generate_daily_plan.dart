import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/api/models/generate_daily_plan_request_strategy.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../repositories/supervisor_repository.dart';

/// Command: encola la planificación automática de un día (pedidos → camiones,
/// orden de paradas y plan de carga). Es asíncrona: devuelve la corrida y el
/// resultado se consulta con [GetDailyPlanRun]. Repetirla el mismo día
/// devuelve la corrida que ya existe.
class GenerateDailyPlan {
  const GenerateDailyPlan(this._repo);

  final SupervisorRepository _repo;

  Future<AutoPlanRun> call(DateTime day) => _repo.generateDailyPlan(
    planDate: day,
    strategy: GenerateDailyPlanRequestStrategy.optimization,
  );
}

final generateDailyPlanProvider = Provider<GenerateDailyPlan>(
  (ref) => GenerateDailyPlan(ref.watch(supervisorRepositoryProvider)),
);
