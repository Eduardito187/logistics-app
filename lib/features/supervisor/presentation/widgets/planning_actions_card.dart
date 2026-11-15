import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/api/models/auto_plan_run_status.dart';
import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/plan_status.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/realtime/realtime_bus.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/section_card.dart';
import '../../domain/usecases/generate_daily_plan.dart';
import '../../domain/usecases/publish_plan.dart';
import '../controllers/planning_controllers.dart';
import '../controllers/supervisor_controllers.dart';

/// Acciones del planificador sobre el día: planificar (automático, en segundo
/// plano) y publicar todos los planes que todavía no se publicaron.
///
/// Mientras la planificación corre, su avance llega en tiempo real; sin
/// socket consulta su estado cada [pollEvery]. Al terminar refresca la lista
/// de planes.
class PlanningActionsCard extends ConsumerStatefulWidget {
  const PlanningActionsCard({
    super.key,
    required this.date,
    this.pollEvery = const Duration(seconds: 5),
  });

  final DateTime date;
  final Duration pollEvery;

  @override
  ConsumerState<PlanningActionsCard> createState() =>
      _PlanningActionsCardState();
}

class _PlanningActionsCardState extends ConsumerState<PlanningActionsCard> {
  Timer? _poll;
  bool _busy = false;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  static bool _running(AutoPlanRun? run) =>
      run?.status == AutoPlanRunStatus.queued ||
      run?.status == AutoPlanRunStatus.processing;

  /// Planes del día que se pueden publicar: sin publicar y con paradas.
  static List<Plan> _publishable(List<Plan>? plans) => [
    for (final plan in plans ?? const <Plan>[])
      if (plan.status != PlanStatus.published && plan.stops.isNotEmpty) plan,
  ];

  /// Sigue la corrida: mientras esté en curso vuelve a consultarla; cuando
  /// termina, la lista de planes se pide de nuevo.
  ///
  /// Con tiempo real el avance llega por socket (lo escucha la pantalla de
  /// planes); la consulta cada [PlanningActionsCard.pollEvery] es solo el
  /// respaldo cuando no hay socket.
  void _follow(AutoPlanRun? previous, AutoPlanRun? run) {
    _poll?.cancel();
    if (_running(run)) {
      if (ref.read(realtimeTopicLiveProvider(RealtimeTopic.planning))) return;
      _poll = Timer(widget.pollEvery, () {
        if (mounted) ref.invalidate(dailyPlanRunProvider);
      });
    } else if (_running(previous)) {
      ref.invalidate(plansProvider);
    }
  }

  Future<void> _plan() async {
    setState(() => _busy = true);
    try {
      await ref.read(generateDailyPlanProvider)(widget.date);
      if (!mounted) return;
      ref.invalidate(dailyPlanRunProvider);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publishAll(List<Plan> plans) async {
    final count = plans.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          count == 1 ? '¿Publicar el plan?' : '¿Publicar $count planes?',
        ),
        content: const Text(
          'Los preparadores y los choferes van a ver estos planes y empezar '
          'a trabajar con ellos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    var published = 0;
    Object? firstError;
    final publish = ref.read(publishPlanProvider);
    for (final plan in plans) {
      try {
        await publish(plan.id);
        published++;
      } on Object catch (error) {
        firstError ??= error;
      }
    }
    if (!mounted) return;
    ref.invalidate(plansProvider);
    setState(() => _busy = false);
    if (firstError != null) {
      showErrorSnack(context, firstError);
    } else {
      showSuccessSnack(
        context,
        published == 1 ? 'Plan publicado.' : 'Se publicaron $published planes.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AutoPlanRun?>>(
      dailyPlanRunProvider,
      (previous, next) => _follow(previous?.value, next.value),
    );
    // Se conectó o se cayó el socket: se consulta una vez (por lo que se haya
    // perdido) y eso reacomoda el respaldo.
    ref.listen(
      realtimeTopicLiveProvider(RealtimeTopic.planning),
      (_, _) => ref.invalidate(dailyPlanRunProvider),
    );
    final theme = Theme.of(context);
    final run = ref.watch(dailyPlanRunProvider).value;
    final running = _running(run);
    final publishable = _publishable(ref.watch(plansProvider).value);
    final today = DateTime.now();
    final past = widget.date.isBefore(
      DateTime(today.year, today.month, today.day),
    );
    final status = _statusText(run);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SectionCard(
        title: 'Planificación del día',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (status != null) ...[
              Text(status, style: theme.textTheme.bodyLarge),
              if (run != null &&
                  run.status == AutoPlanRunStatus.completed &&
                  run.unassignedCount > 0)
                Text(
                  run.unassignedCount == 1
                      ? '1 pedido quedó sin camión.'
                      : '${run.unassignedCount} pedidos quedaron sin camión.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 12),
            ],
            if (!past)
              FilledButton.icon(
                onPressed: _busy || running ? null : _plan,
                icon: AnimatedAppIcon(
                  AppIcon.plans,
                  state: _busy ? AppIconState.loading : AppIconState.idle,
                  excludeFromSemantics: true,
                ),
                label: Text(running ? 'Planificando…' : 'Planificar el día'),
              ),
            if (!past) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => context.push('/supervisor/trips/new'),
                icon: const AnimatedAppIcon(
                  AppIcon.route,
                  excludeFromSemantics: true,
                ),
                label: const Text('Armar un viaje a mano'),
              ),
            ],
            if (publishable.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _publishAll(publishable),
                icon: const AnimatedAppIcon(
                  AppIcon.send,
                  excludeFromSemantics: true,
                ),
                label: Text(
                  publishable.length == 1
                      ? 'Publicar 1 plan'
                      : 'Publicar los ${publishable.length} planes',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _statusText(AutoPlanRun? run) {
    if (run == null) return 'Este día todavía no se planificó.';
    return switch (run.status) {
      AutoPlanRunStatus.queued || AutoPlanRunStatus.processing =>
        'Armando los planes. Puede tardar unos '
            'minutos; podés seguir usando la app.',
      AutoPlanRunStatus.completed =>
        'Planificado: ${run.trucksPlanned} camiones, '
            '${run.stopsPlanned} paradas.',
      AutoPlanRunStatus.failed =>
        'No se pudo planificar${run.failureReason == null ? '.' : ': ${run.failureReason}'}',
      AutoPlanRunStatus.$unknown => null,
    };
  }
}
