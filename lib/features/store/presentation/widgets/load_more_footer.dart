import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';

/// Pie de una lista con scroll infinito: spinner mientras llega la página,
/// aviso con "Reintentar" si falló y, si no, un botón grande para pedirla a
/// mano.
///
/// El botón manual existe aunque el scroll ya dispare la carga: si la lista
/// entra entera en la pantalla (tablet, letra chica) no hay desplazamiento que
/// la dispare, y con guantes conviene tener algo que tocar.
class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.loading,
    required this.failed,
    required this.onLoadMore,
    this.label = 'Cargar más',
    this.loadingLabel = 'Cargando más…',
    this.failedLabel = 'No se pudo cargar más.',
  });

  /// Hay una página en vuelo.
  final bool loading;

  /// La última página pedida falló.
  final bool failed;

  final VoidCallback onLoadMore;

  final String label;
  final String loadingLabel;
  final String failedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(loadingLabel, style: theme.textTheme.bodyMedium),
        ],
      );
    }
    return Column(
      children: [
        if (failed) ...[
          Text(
            failedLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: onLoadMore,
          icon: AnimatedAppIcon(
            failed ? AppIcon.refresh : AppIcon.expandMore,
            excludeFromSemantics: true,
          ),
          label: Text(failed ? 'Reintentar' : label),
        ),
      ],
    );
  }
}
