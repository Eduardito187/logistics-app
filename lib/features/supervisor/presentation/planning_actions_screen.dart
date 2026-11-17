import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/icons.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/planning_controllers.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/planning_actions_card.dart';
import 'widgets/plans_date_bar.dart';

/// Pantalla de CREAR/gestionar la planificación del día: elegir la fecha,
/// planificar automático, armar un viaje a mano y publicar. Está separada del
/// LISTADO (`SupervisorPlansScreen`): ver y crear no se mezclan en la misma
/// página (como el resto de los módulos del admin). Solo para quien planifica
/// (planificador / administrador); el supervisor solo mira (ve el listado).
class PlanningActionsScreen extends ConsumerWidget {
  const PlanningActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPlan = ref.watch(canPlanProvider);
    final date = ref.watch(plansDateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Planificación del día')),
      body: canPlan
          ? ResponsiveBody(
              maxWidth: AppBreakpoints.maxFormWidth,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  PlansDateBar(date: date),
                  PlanningActionsCard(date: date),
                ],
              ),
            )
          : const EmptyState(
              icon: AppIcon.plans,
              title: 'Solo lectura',
              message: 'No tenés permiso para planificar. Mirá las rutas en '
                  'la sección de rutas.',
            ),
    );
  }
}
