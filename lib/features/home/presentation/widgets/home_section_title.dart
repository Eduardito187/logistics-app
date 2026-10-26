import 'package:flutter/material.dart';

/// Título de sección del inicio, en condensada bold (titleLarge w800), con una
/// acción opcional a la derecha (p. ej. "Ver todo").
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// Texto del botón de acción a la derecha; si es `null`, no se muestra.
  final String? actionLabel;

  /// Acción del botón; se ignora si [actionLabel] es `null`.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}
