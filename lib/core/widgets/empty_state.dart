import 'package:flutter/material.dart';

import '../icons/icons.dart';

/// Estado vacío/ilustrativo reutilizable (sin datos, error, sin permiso).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  /// Ícono animado DisTrack (se dibuja al aparecer).
  final AppIcon icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícono decorativo: el lector de pantalla lee título y mensaje.
          AnimatedAppIcon(
            icon,
            size: 64,
            color: theme.colorScheme.outline,
            animateOnMount: true,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 16),
          Semantics(
            container: true,
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
    // Centrado y del tamaño de su contenido si entra; si no entra (teléfono
    // chico, teclado abierto, letra grande) se desplaza en vez de desbordar.
    // Sin LayoutBuilder: SliverFillRemaining(hasScrollBody: false) pide
    // dimensiones intrínsecas y LayoutBuilder no las soporta.
    return Center(child: SingleChildScrollView(child: content));
  }
}
