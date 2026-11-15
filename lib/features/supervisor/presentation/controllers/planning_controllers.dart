import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/realtime/pusher_socket.dart';
import '../../domain/usecases/get_daily_plan_run.dart';
import 'plans_date_notifier.dart';

/// ¿El usuario puede planificar (generar, ajustar y publicar planes)? Lo
/// decide su rol: planificador o administrador. El supervisor solo mira.
final canPlanProvider = Provider<bool>(
  (ref) => ref.watch(sessionProvider.select((s) => s?.role.canPlan ?? false)),
);

/// ¿Un evento de tiempo real de planificación es del día [date]? Si el evento
/// no trae fecha (`plan_date`, `Y-m-d`), se asume que sí.
bool planEventIsFor(RealtimeEvent event, DateTime date) {
  final raw = event.data['plan_date'];
  if (raw is! String || raw.length < 10) return true;
  final day = DateTime.tryParse(raw.substring(0, 10));
  return day == null ||
      (day.year == date.year && day.month == date.month && day.day == date.day);
}

/// Corrida de planificación automática del día seleccionado (`null` = ese día
/// no se planificó todavía).
final dailyPlanRunProvider = FutureProvider.autoDispose<AutoPlanRun?>((ref) {
  final date = ref.watch(plansDateProvider);
  return ref.watch(getDailyPlanRunProvider)(date);
});
