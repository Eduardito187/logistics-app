import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/role_task.dart';
import '../../../../core/theme/app_colors.dart';

/// Tarjeta de acción del inicio: representa un flujo (tarea) disponible para el
/// rol y navega a su ruta al tocarla.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, this.maxLines});

  final RoleTask task;

  /// Límite de líneas de título y subtítulo (con elipsis). `null` en la lista
  /// del teléfono (alto natural); [gridLines] en la grilla de tablet, donde
  /// todas las tarjetas tienen el mismo alto ([gridExtent]).
  final int? maxLines;

  /// Líneas de título y de subtítulo en la grilla.
  static const int gridLines = 2;

  /// Alto de la tarjeta en la grilla según el tema y la letra del sistema
  /// (ya limitada a 1.3x): padding (2×18) + título (titleMedium) y subtítulo
  /// (bodyMedium) de hasta [gridLines] líneas + separación, con un margen de
  /// redondeo. Nunca menor al ícono (54) + padding.
  static double gridExtent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    double lineHeight(TextStyle? style) {
      final size = scaler.scale(style?.fontSize ?? 14);
      return size * (style?.height ?? 1.2);
    }

    final text =
        (lineHeight(textTheme.titleMedium) + lineHeight(textTheme.bodyMedium)) *
            gridLines +
        2;
    return 36 + (text > 54 ? text : 54) + 4;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = task.accent;
    final bg = accent ? AppColors.accent : theme.cardColor;
    final fg = accent ? AppColors.accentInk : theme.colorScheme.onSurface;
    return Card(
      color: bg,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(task.route),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent
                      ? AppColors.accentInk.withValues(alpha: 0.12)
                      : theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  task.icon,
                  size: 28,
                  color: accent
                      ? AppColors.accentInk
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.label,
                      maxLines: maxLines,
                      overflow: maxLines == null ? null : TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    if (task.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.subtitle!,
                        maxLines: maxLines,
                        overflow: maxLines == null
                            ? null
                            : TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fg.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: fg.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
