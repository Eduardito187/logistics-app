import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/auth/session.dart';
import '../../domain/usecases/get_daily_plan_run.dart';
import 'plans_date_notifier.dart';

/// ¿El usuario puede planificar (generar, ajustar y publicar planes)? Lo
/// decide su rol: planificador o administrador. El supervisor solo mira.
final canPlanProvider = Provider<bool>(
  (ref) => ref.watch(sessionProvider.select((s) => s?.role.canPlan ?? false)),
);

/// Corrida de planificación automática del día seleccionado (`null` = ese día
/// no se planificó todavía).
final dailyPlanRunProvider = FutureProvider.autoDispose<AutoPlanRun?>((ref) {
  final date = ref.watch(plansDateProvider);
  return ref.watch(getDailyPlanRunProvider)(date);
});
