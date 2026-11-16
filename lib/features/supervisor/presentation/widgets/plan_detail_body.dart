import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/plan_status.dart';
import '../../../../core/api/models/planned_stop.dart';
import '../../../../core/icons/icons.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/status_pill.dart';
import '../controllers/planning_controllers.dart';
import '../supervisor_labels.dart';
import '../vehicle_label.dart';
import 'detail_row.dart';
import 'plan_editor.dart';
import 'stop_tile.dart';

/// Cuerpo del detalle de un plan: cabecera, métricas y el recorrido como una
/// LÍNEA DE TIEMPO de tarjetas (una por parada, con su hora de llegada).
///
/// Es `StatelessWidget`: lo único que lee de Riverpod (la placa del camión) va
/// en [_VehicleTitle], así que la carga de placas reconstruye solo ese texto y
/// no vuelve a ordenar las paradas ni a armar todo el detalle.
class PlanDetailBody extends StatelessWidget {
  const PlanDetailBody({
    super.key,
    required this.plan,
    required this.planId,
    this.canPlan = false,
  });

  final Plan plan;
  final String planId;

  /// El usuario planifica: un plan sin publicar se puede ordenar, completar
  /// y publicar. Publicado, o para quien solo mira, es de solo lectura.
  final bool canPlan;

  @override
  Widget build(BuildContext context) {
    final stops = [...plan.stops]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final finalEta = planFinalEta(stops);

    final header = SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _VehicleTitle(vehicleId: plan.vehicleId)),
              StatusPill(
                planStatusLabel(plan.status),
                tone: planStatusTone(plan.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DetailRow(label: 'Fecha', value: formatDay(plan.planDate)),
          if (plan.driverName != null)
            DetailRow(label: 'Chofer', value: plan.driverName!),
          if (plan.originNode != null)
            DetailRow(label: 'Sale de', value: plan.originNode!.name),
          if (plan.distanceKm != null)
            DetailRow(label: 'Recorrido', value: formatKm(plan.distanceKm!)),
          if (plan.durationMinutes != null)
            DetailRow(
              label: 'Duración',
              value: formatDuration(plan.durationMinutes!),
            ),
          if (plan.routeGeometry != null)
            const DetailRow(label: 'Ruta', value: 'Trazado disponible'),
        ],
      ),
    );
    final stats = Row(
      children: [
        Expanded(
          child: StatTile(
            value: '${stops.length}',
            label: 'Paradas',
            icon: AppIcon.place,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            value: finalEta == null ? '—' : formatHour(finalEta),
            label: 'ETA final',
            icon: AppIcon.pending,
            color: AppColors.info,
          ),
        ),
      ],
    );
    // Nota (512 MB): esta es la ÚNICA lista que se arma eager (Column), pero es
    // una pantalla de SUPERVISOR (tablet/oficina), no del personal de terreno
    // con teléfonos de 512 MB. Con ~20-60 StopTile livianos en tablet es
    // aceptable; virtualizar exigiría CustomScrollView/slivers (romper el
    // SectionCard) sin beneficio en el equipo objetivo. Se deja a propósito.
    final stopsCard = SectionCard(
      title: 'Secuencia de paradas',
      child: canPlan && plan.status != PlanStatus.published
          ? PlanEditor(plan: plan)
          : stops.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('El plan todavía no tiene paradas.'),
            )
          : _StopsTimeline(planId: planId, stops: stops),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablet grande: resumen a la izquierda y el recorrido a la derecha.
        final wide =
            AppBreakpoints.sizeFor(constraints.maxWidth) == WindowSize.expanded;
        if (wide) {
          return ResponsiveBody(
            maxWidth: _maxWideWidth,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [header, const SizedBox(height: 16), stats],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: stopsCard),
                  ],
                ),
              ],
            ),
          );
        }
        return ResponsiveBody(
          maxWidth: AppBreakpoints.maxContentWidth,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              header,
              const SizedBox(height: 16),
              stats,
              const SizedBox(height: 16),
              stopsCard,
            ],
          ),
        );
      },
    );
  }
}

/// Paradas de solo lectura como línea de tiempo, cada una con su hora
/// estimada de llegada (lo único de acá que escucha la ETA).
class _StopsTimeline extends ConsumerWidget {
  const _StopsTimeline({required this.planId, required this.stops});

  final String planId;
  final List<PlannedStop> stops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etas = ref.watch(planStopEtasProvider(planId));
    return Column(
      children: [
        for (var i = 0; i < stops.length; i++)
          StopTile(
            position: i + 1,
            stop: stops[i],
            // La ETA en vivo del plan; si no hay, la planificada.
            eta: etas[stops[i].shipmentId] ?? stops[i].etaAt,
            isFirst: i == 0,
            isLast: i == stops.length - 1,
          ),
      ],
    );
  }
}

/// "Camión" + placa del encabezado; único widget del detalle que escucha las
/// placas de la flota.
class _VehicleTitle extends ConsumerWidget {
  const _VehicleTitle({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      vehicleLabel(ref, vehicleId),
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

/// Ancho máximo del detalle en tablets grandes (dos columnas).
const double _maxWideWidth = 1120;
