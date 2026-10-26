import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tile de acción grande y amable para la grilla del inicio.
///
/// Fila con un cuadro redondeado tintado (rojo de marca o, con [accent], ámbar
/// de alerta/en-curso), la etiqueta grande, un subtítulo opcional de hasta dos
/// líneas y un chevron atenuado. Borde sutil como las tarjetas del tema y
/// ripple al tocar.
class BigActionTile extends StatelessWidget {
  const BigActionTile({
    super.key,
    required this.label,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  /// Variante de acento ámbar (alertas / en-curso); por defecto, rojo de marca.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final boxColor = accent
        ? AppColors.accent.withValues(alpha: 0.15)
        : AppColors.brand.withValues(alpha: 0.10);
    final iconColor = accent ? AppColors.accentInk : AppColors.brand;

    return Material(
      color: scheme.surface,
      // Solo `shape` (no `borderRadius`): Material no admite ambos a la vez. El
      // RoundedRectangleBorder ya define el radio y el borde sutil.
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: boxColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
