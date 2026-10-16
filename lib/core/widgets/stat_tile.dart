import 'package:flutter/material.dart';

/// Mosaico de métrica: número grande + etiqueta. Usado en los resúmenes de
/// chofer y supervisor (estilo "finanzas" de los mockups).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: tint, size: 24),
            const SizedBox(height: 8),
          ],
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: tint,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
