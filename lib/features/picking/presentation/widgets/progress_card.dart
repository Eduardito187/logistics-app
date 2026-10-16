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
    required this.onAssign,
    required this.onPrintAll,
    required this.onReprintBatch,
  });

  final int prepared;
  final int total;
  final String? lane;
  final bool busy;
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
          Row(
            children: [
              Icon(
                Icons.alt_route,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lane == null || lane!.isEmpty
                      ? 'Carril / vehículo sin asignar'
                      : 'Carril / vehículo: $lane',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: onAssign,
                child: Text(lane == null ? 'Asignar' : 'Cambiar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onPrintAll,
            icon: busy ? const ButtonSpinner() : const Icon(Icons.print),
            label: const Text('Imprimir todas las etiquetas'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onReprintBatch,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reimprimir lote'),
          ),
        ],
      ),
    );
  }
}
