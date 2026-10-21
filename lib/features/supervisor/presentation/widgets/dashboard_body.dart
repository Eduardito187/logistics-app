import 'package:flutter/material.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../domain/dashboard_metrics.dart';
import '../supervisor_labels.dart';

/// Cuerpo del tablero: tarjeta de resumen y grilla de métricas del día.
class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key, required this.metrics, required this.date});

  final DashboardMetrics metrics;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final rate = metrics.fulfillmentRate;
    final rateLabel = rate == null ? '—' : '${(rate * 100).round()}%';

    final tiles = <Widget>[
      StatTile(
        value: '${metrics.delivered}',
        label: 'Entregadas',
        icon: Icons.check_circle,
        color: AppColors.success,
      ),
      StatTile(
        value: '${metrics.inExecution}',
        label: 'En ruta',
        icon: Icons.local_shipping,
        color: AppColors.info,
      ),
      StatTile(
        value: '${metrics.failed}',
        label: 'Fallidas',
        icon: Icons.cancel,
        color: AppColors.danger,
      ),
      StatTile(
        value: rateLabel,
        label: 'Cumplimiento',
        icon: Icons.verified,
        color: AppColors.brand,
      ),
      StatTile(
        value: '${metrics.pending}',
        label: 'Por salir',
        icon: Icons.inventory_2,
        color: AppColors.warning,
      ),
      StatTile(
        value: '${metrics.activePlans}',
        label: 'Rutas en curso',
        icon: Icons.alt_route,
        color: AppColors.brand,
      ),
    ];

    // En tablet el tablero no se estira de borde a borde: hasta ~1040 dp con
    // 3 mosaicos por fila; en teléfono, 2 por fila.
    return ResponsiveBody(
      maxWidth: _maxDashboardWidth,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Resumen de ${formatDay(date)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${metrics.total} envíos del día en total'),
                const SizedBox(height: 4),
                Text('${metrics.openAlerts} alertas sin reconocer'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => _TileGrid(
              columns: AppBreakpoints.columnsFor(constraints.maxWidth) == 1
                  ? 2
                  : 3,
              tiles: tiles,
            ),
          ),
        ],
      ),
    );
  }
}

const double _maxDashboardWidth = 1040;

/// Grilla de mosaicos sin alto fijo: filas de [columns] mosaicos que se
/// igualan en alto. A diferencia de `GridView.count` con `childAspectRatio`,
/// la letra grande (1.3x) en un teléfono de 320 dp no desborda el mosaico.
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.columns, required this.tiles});

  final int columns;
  final List<Widget> tiles;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < tiles.length; start += columns) {
      if (start > 0) rows.add(const SizedBox(height: _gap));
      rows.add(
        // Son 6 mosaicos fijos: IntrinsicHeight es barato y deja las filas
        // parejas aunque una etiqueta ocupe dos líneas.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: _gap),
                Expanded(
                  child: start + i < tiles.length
                      ? tiles[start + i]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
