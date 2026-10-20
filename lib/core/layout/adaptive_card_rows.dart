import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Columnas efectivas para [width]: [AppBreakpoints.columnsFor] con tope
/// [maxColumns] (y nunca menos de 1).
int adaptiveColumnsFor(double width, {int maxColumns = 3}) =>
    math.max(1, math.min(maxColumns, AppBreakpoints.columnsFor(width)));

/// Arma la fila [row] de [columns] tarjetas: alineadas arriba, sin alto fijo
/// (la fila toma la altura de la tarjeta más alta) y celdas vacías al final.
Widget _buildCardRow(
  BuildContext context, {
  required int row,
  required int columns,
  required int itemCount,
  required IndexedWidgetBuilder itemBuilder,
  required double columnSpacing,
}) {
  final start = row * columns;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var column = 0; column < columns; column++) ...[
        if (column > 0) SizedBox(width: columnSpacing),
        Expanded(
          child: start + column < itemCount
              ? itemBuilder(context, start + column)
              : const SizedBox.shrink(),
        ),
      ],
    ],
  );
}

/// Lista perezosa de tarjetas en columnas (versión sliver): 1 en teléfono,
/// 2–3 en tablet según [AppBreakpoints.columnsFor] sobre el ancho real del
/// sliver.
///
/// Construye solo las filas visibles (`SliverList`), así una lista larga no
/// infla cientos de tarjetas en un teléfono de 1 GB. Las tarjetas de una fila
/// se alinean arriba y no necesitan alto fijo: cada fila toma la altura de su
/// tarjeta más alta (con letra grande no desborda, a diferencia de un
/// `GridView` con `childAspectRatio`).
class SliverAdaptiveCardRows extends StatelessWidget {
  const SliverAdaptiveCardRows({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 12,
    this.columnSpacing = 12,
    this.maxColumns = 3,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Separación vertical entre filas.
  final double spacing;

  /// Separación horizontal entre columnas.
  final double columnSpacing;

  /// Tope de columnas (p. ej. 2 para tarjetas con acciones anchas).
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = adaptiveColumnsFor(
          constraints.crossAxisExtent,
          maxColumns: maxColumns,
        );
        if (columns == 1) {
          return SliverList.separated(
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            separatorBuilder: (_, _) => SizedBox(height: spacing),
          );
        }
        return SliverList.separated(
          itemCount: (itemCount / columns).ceil(),
          separatorBuilder: (_, _) => SizedBox(height: spacing),
          itemBuilder: (context, row) => _buildCardRow(
            context,
            row: row,
            columns: columns,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            columnSpacing: columnSpacing,
          ),
        );
      },
    );
  }
}

/// Versión caja de [SliverAdaptiveCardRows]: un `ListView` perezoso con
/// [padding] propio, para pantallas cuyo cuerpo es solo la lista de tarjetas.
///
/// Las columnas se calculan sobre el ancho total disponible (padding incluido).
class AdaptiveCardRows extends StatelessWidget {
  const AdaptiveCardRows({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
    this.columnSpacing = 12,
    this.maxColumns = 3,
    this.physics,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;

  /// Separación vertical entre filas.
  final double spacing;

  /// Separación horizontal entre columnas.
  final double columnSpacing;

  /// Tope de columnas.
  final int maxColumns;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = adaptiveColumnsFor(
          constraints.maxWidth,
          maxColumns: maxColumns,
        );
        if (columns == 1) {
          return ListView.separated(
            padding: padding,
            physics: physics,
            itemCount: itemCount,
            separatorBuilder: (_, _) => SizedBox(height: spacing),
            itemBuilder: itemBuilder,
          );
        }
        return ListView.separated(
          padding: padding,
          physics: physics,
          itemCount: (itemCount / columns).ceil(),
          separatorBuilder: (_, _) => SizedBox(height: spacing),
          itemBuilder: (context, row) => _buildCardRow(
            context,
            row: row,
            columns: columns,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            columnSpacing: columnSpacing,
          ),
        );
      },
    );
  }
}
