import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';

/// Tarjeta grande y táctil para UNA decisión (con guantes y una mano): ícono
/// en círculo, título, una línea de ayuda y, a la derecha, un indicador
/// opcional ([trailing]) o la flecha. Mínimo 72 dp de alto.
class PrinterOptionCard extends StatelessWidget {
  const PrinterOptionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.trailing,
    super.key,
  });

  final AppIcon icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Marca la opción elegida (borde y fondo del color primario, check).
  final bool selected;

  /// Reemplaza la flecha (p. ej. una pastilla "Zebra").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedAppIcon(
                      selected ? AppIcon.success : icon,
                      state: selected
                          ? AppIconState.success
                          : AppIconState.idle,
                      size: 28,
                      color: scheme.primary,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
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
                  // Tope de ancho: con letra grande en 320 dp la pastilla se
                  // acorta (elipsis) en vez de empujar el título.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child:
                        trailing ??
                        AnimatedAppIcon(
                          AppIcon.chevronRight,
                          color: scheme.onSurfaceVariant,
                          excludeFromSemantics: true,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
