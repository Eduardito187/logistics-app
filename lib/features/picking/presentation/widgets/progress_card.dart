import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';
import 'button_spinner.dart';

/// Tarjeta de progreso del armado: preparadas/pendientes, carril asignado y las
/// acciones a nivel pedido (asignar carril, imprimir todas, reimprimir lote).
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.prepared,
    required this.total,
    required this.lane,
    required this.busy,
    this.reprinting = false,
    required this.onAssign,
    required this.onPrintAll,
    required this.onReprintBatch,
  });

  final int prepared;
  final int total;
  final String? lane;

  /// Hay una operación a nivel pedido en curso: deshabilita las acciones.
  final bool busy;

  /// La operación en curso es "Reimprimir lote": el spinner va en ese botón y
  /// no en "Imprimir todas".
  final bool reprinting;
  final VoidCallback onAssign;
  final VoidCallback onPrintAll;
  final VoidCallback onReprintBatch;

  @override
  Widget build(BuildContext context) {
    final pending = total - prepared;
    final done = total > 0 && prepared == total;
    return SectionCard(
      title: 'Progreso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '$prepared/$total',
                  label: 'Preparadas',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: '$pending',
                  label: 'Pendientes',
                  icon: Icons.inventory_2,
                  color: done ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LaneRow(lane: lane, onAssign: onAssign),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onPrintAll,
            icon: busy && !reprinting
                ? const ButtonSpinner()
                : const Icon(Icons.print),
            label: const Text('Imprimir todas las etiquetas'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onReprintBatch,
            icon: reprinting
                ? const ButtonSpinner()
                : const Icon(Icons.restart_alt),
            label: const Text('Reimprimir lote'),
          ),
        ],
      ),
    );
  }
}

/// Carril/vehículo asignado con su acción. En un teléfono chico con letra
/// grande el botón baja debajo del texto: al lado, le dejaba ~50 dp al texto y
/// la tarjeta crecía cientos de dp (una palabra por línea).
class _LaneRow extends StatelessWidget {
  const _LaneRow({required this.lane, required this.onAssign});

  final String? lane;
  final VoidCallback onAssign;

  /// Ancho de contenido por debajo del cual el botón va en su propia línea.
  static const double _stackBelow = 400;

  @override
  Widget build(BuildContext context) {
    final lane = this.lane;
    final text = Text(
      lane == null || lane.isEmpty
          ? 'Carril / vehículo sin asignar'
          : 'Carril / vehículo: $lane',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    final button = TextButton(
      onPressed: onAssign,
      child: Text(lane == null ? 'Asignar' : 'Cambiar'),
    );
    final icon = Icon(
      Icons.alt_route,
      color: Theme.of(context).colorScheme.primary,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _stackBelow) {
          return Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(child: text),
              button,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: text),
              ],
            ),
            Align(alignment: AlignmentDirectional.centerEnd, child: button),
          ],
        );
      },
    );
  }
}
