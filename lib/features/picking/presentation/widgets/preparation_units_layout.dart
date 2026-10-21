import 'package:flutter/material.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/layout/responsive_body.dart';

/// Disposición del armado con unidades: en teléfono y tablet chica, progreso,
/// título y unidades en una sola lista; en tablet grande, el progreso queda
/// fijo a la izquierda y las unidades a la derecha (lista + detalle).
class PreparationUnitsLayout extends StatelessWidget {
  const PreparationUnitsLayout({
    super.key,
    required this.progress,
    required this.title,
    required this.unitRows,
    required this.onRefresh,
  });

  /// Tarjeta de progreso y acciones del pedido.
  final Widget progress;

  /// Título "Unidades (N)".
  final Widget title;

  /// Sliver con las unidades (perezoso).
  final Widget unitRows;

  final RefreshCallback onRefresh;

  /// Ancho del panel de progreso en tablets grandes.
  static const double sidePaneWidth = 400;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            AppBreakpoints.sizeFor(constraints.maxWidth) == WindowSize.expanded;
        if (!wide) {
          return ResponsiveBody(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList.list(
                      children: [
                        progress,
                        const SizedBox(height: 16),
                        title,
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: unitRows,
                  ),
                ],
              ),
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: sidePaneWidth,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                children: [progress],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(child: title),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: unitRows,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
