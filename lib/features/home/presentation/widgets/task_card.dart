import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/role_task.dart';
import '../../../../core/theme/app_colors.dart';

/// Tarjeta de acción del inicio: representa un flujo (tarea) disponible para el
/// rol y navega a su ruta al tocarla.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final RoleTask task;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    if (task.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.subtitle!,
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
