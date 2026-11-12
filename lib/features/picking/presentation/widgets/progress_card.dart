import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';

/// Tarjeta de progreso del armado: preparadas/pendientes, carril asignado y las
/// acciones a nivel pedido (asignar carril, imprimir todas).
///
/// Etiquetas GLOBALES y PERMANENTES (decisión del dueño, nov 2026): NO existe
/// "reemitir/anular" — una etiqueta nunca se invalida ni se regenera. Si se
/// dañó, se vuelve a imprimir la MISMA ("Imprimir todas").
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.prepared,
    required this.total,
    required this.lane,
    required this.busy,
    required this.onAssign,
    required this.onPrintAll,
    this.onMarkPrepared,
  });

  final int prepared;
  final int total;
  final String? lane;

  /// Hay una operación a nivel pedido en curso: deshabilita las acciones.
  final bool busy;
  final VoidCallback onAssign;
  final VoidCallback onPrintAll;

  /// Marca a mano como preparadas las etiquetas que falten. `null` cuando ya
  /// están todas preparadas (el botón no se muestra). Exige vehículo asignado:
  /// esa validación la hace la pantalla.
  final VoidCallback? onMarkPrepared;

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
                  label: 'Preparados',
                  icon: AppIcon.success,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  value: '$pending',
                  label: 'Por preparar',
                  icon: AppIcon.receive,
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
            // Mientras imprime, la hoja sale de la impresora (loop de impresión).
            icon: AnimatedAppIcon(
              AppIcon.printing,
              state: busy ? AppIconState.loading : AppIconState.idle,
            ),
            label: const Text('Imprimir todas las etiquetas'),
          ),
          // Quedan etiquetas sin preparar: se pueden marcar a mano (requiere
          // vehículo asignado; si falta, la pantalla lo pide primero).
          if (onMarkPrepared != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onMarkPrepared,
              icon: const AnimatedAppIcon(AppIcon.success),
              label: const Text('Marcar como preparadas'),
            ),
          ],
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
    final theme = Theme.of(context);
    final lane = this.lane;
    final text = Text(
      lane == null || lane.isEmpty
          ? 'Vehículo de reparto sin asignar'
          : 'Vehículo: $lane',
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    );
    final button = TextButton(
      onPressed: onAssign,
      child: Text(lane == null ? 'Asignar' : 'Cambiar'),
    );
    final icon = AnimatedAppIcon(
      AppIcon.plans,
      color: Theme.of(context).colorScheme.onSurface,
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
