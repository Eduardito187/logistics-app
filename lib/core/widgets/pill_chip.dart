import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pastilla seleccionable (filtro) con forma "pill" (radio 999).
///
/// Seleccionada: fondo [AppColors.brand] y texto blanco. Sin seleccionar: fondo
/// de superficie con un borde sutil y texto en `onSurface`. Alto ≥ 44 y padding
/// generoso para tocar con guantes; muestra ripple al tocar.
///
/// Se declara junto a [PillChipsRow] en el mismo archivo por ser un par natural
/// (la pastilla y su fila scrollable): la fila solo compone pastillas y no tiene
/// sentido una sin la otra.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = selected ? AppColors.brand : scheme.surface;
    final fg = selected ? Colors.white : scheme.onSurface;
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          selected: selected,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila horizontal scrollable de [PillChip] con selección única.
///
/// Par natural de [PillChip] (ver nota en esa clase). Expone la pastilla
/// activa por índice y avisa el nuevo índice al tocar.
class PillChipsRow extends StatelessWidget {
  const PillChipsRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            PillChip(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}
