import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/plan.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/status_pill.dart';
import '../supervisor_labels.dart';
import '../vehicle_label.dart';
import 'detail_row.dart';
import 'eta_section.dart';
import 'stop_tile.dart';

/// Cuerpo del detalle (solo lectura) de un plan: cabecera, métricas, ETA y la
/// secuencia de paradas.
///
/// Es `StatelessWidget`: lo único que lee de Riverpod (la placa del camión) va
/// en [_VehicleTitle], así que la carga de placas reconstruye solo ese texto y
/// no vuelve a ordenar las paradas ni a armar todo el detalle.
class PlanDetailBody extends StatelessWidget {
  const PlanDetailBody({super.key, required this.plan, required this.planId});

  final Plan plan;
  final String planId;

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
          DetailRow(label: 'Plan', value: plan.id, mono: true),
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
            icon: Icons.pin_drop,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            value: finalEta == null ? '—' : formatHour(finalEta),
            label: 'ETA final',
            icon: Icons.schedule,
            color: AppColors.info,
          ),
        ),
      ],
    );
    final stopsCard = SectionCard(
      title: 'Secuencia de paradas',
      child: stops.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('El plan todavía no tiene paradas.'),
            )
          : Column(
              children: [
                for (var i = 0; i < stops.length; i++)
                  StopTile(position: i + 1, stop: stops[i]),
              ],
            ),
    );
    final eta = EtaSection(planId: planId);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablet grande: ETA y secuencia de paradas lado a lado.
        final wide =
            AppBreakpoints.sizeFor(constraints.maxWidth) == WindowSize.expanded;
        return ResponsiveBody(
          maxWidth: wide ? _maxWideWidth : AppBreakpoints.maxContentWidth,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              header,
              const SizedBox(height: 16),
              stats,
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: eta),
                    const SizedBox(width: 16),
                    Expanded(child: stopsCard),
                  ],
                )
              else ...[
                eta,
                const SizedBox(height: 16),
                stopsCard,
              ],
            ],
          ),
        );
      },
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
