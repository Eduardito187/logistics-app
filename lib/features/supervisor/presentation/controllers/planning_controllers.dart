import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/api/models/stop_eta.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/realtime/pusher_socket.dart';
import '../../domain/usecases/get_daily_plan_run.dart';
import 'supervisor_controllers.dart';

/// ¿El usuario puede planificar (generar, ajustar y publicar planes)? Lo
/// decide su rol: planificador o administrador. El supervisor solo mira.
final canPlanProvider = Provider<bool>(
  (ref) => ref.watch(sessionProvider.select((s) => s?.role.canPlan ?? false)),
);

/// Hora estimada de llegada de cada parada de un plan, por pedido. Vacío
/// mientras la ETA carga o si falla: la línea de tiempo se muestra igual.
final planStopEtasProvider = Provider.autoDispose
    .family<Map<String, DateTime>, String>((ref, planId) {
      final data = ref.watch(planEtaProvider(planId)).value;
      return {
        for (final stop in data?.stops ?? const <StopEta>[])
          if (stop.etaAt != null) stop.shipmentId: stop.etaAt!,
      };
    });

/// Acciones principales del editor de un plan (guardar orden / publicar),
/// que el detalle muestra FIJAS al pie de la pantalla.
typedef PlanEditorActions = ({
  bool busy,
  bool dirty,
  bool canPublish,
  VoidCallback save,
  VoidCallback publish,
});

/// Lo publica el editor del plan mientras está en pantalla (`null` = no hay
/// nada que editar: plan publicado o usuario que solo mira).
class PlanEditorActionsNotifier extends Notifier<PlanEditorActions?> {
  PlanEditorActionsNotifier(this.planId);

  final String planId;

  @override
  PlanEditorActions? build() => null;

  void set(PlanEditorActions? actions) {
    if (actions != state) state = actions;
  }
}

final planEditorActionsProvider = NotifierProvider.autoDispose
    .family<PlanEditorActionsNotifier, PlanEditorActions?, String>(
      PlanEditorActionsNotifier.new,
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
