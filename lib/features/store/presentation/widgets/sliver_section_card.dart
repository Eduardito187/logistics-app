import 'package:flutter/material.dart';

/// Versión "sliver" de `SectionCard`: misma tarjeta (fondo, borde y título del
/// tema) pero su contenido es un sliver, así una lista larga adentro (p. ej.
/// 100+ productos con foto) se construye perezosa: solo las filas visibles se
/// arman y se decodifican sus fotos. Va dentro de un `CustomScrollView`.
class SliverSectionCard extends StatelessWidget {
  const SliverSectionCard({
    super.key,
    required this.title,
    required this.sliver,
    this.header,
  });

  final String title;

  /// Contenido fijo (no perezoso) entre el título y [sliver]: avisos, contador.
  final Widget? header;

  /// Contenido perezoso de la tarjeta (típicamente `SliverList.builder`).
  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardTheme = theme.cardTheme;
    final shape =
        cardTheme.shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        );
    return DecoratedSliver(
      decoration: ShapeDecoration(
        color: cardTheme.color ?? theme.colorScheme.surfaceContainerLow,
        shape: shape,
      ),
      sliver: SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                // Encabezado: el lector de pantalla permite saltar de sección
                // en sección (igual que SectionCard).
                child: Semantics(
                  container: true,
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            if (header != null) SliverToBoxAdapter(child: header),
            sliver,
          ],
        ),
      ),
    );
  }
}
