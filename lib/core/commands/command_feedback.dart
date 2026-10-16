import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'command_outcome.dart';

/// Muestra el SnackBar correcto según cómo respondió el backend al comando.
///
/// Usar SIEMPRE tras ejecutar un comando de escritura con red, en vez de dar un
/// éxito genérico:
/// - [CommandStatus.accepted] (202 async): tono informativo (azul). Deja claro
///   que la orden quedó "en proceso" y todavía NO aplicada. No usar pasado
///   ("aprobado", "pagado"): el estado real llega cuando el backend procese.
/// - [CommandStatus.applied] (sync): tono de éxito (verde). El cambio ya está
///   hecho.
///
/// Si el backend trae un mensaje propio en el [CommandOutcome], se prioriza;
/// si no, se usa el texto por defecto en español.
void showCommandOutcome(BuildContext context, CommandOutcome outcome) {
  final (String message, Color color) = switch (outcome.status) {
    CommandStatus.accepted => (
      outcome.message ?? 'Aceptado. Se está procesando.',
      AppColors.info,
    ),
    CommandStatus.applied => (outcome.message ?? 'Hecho.', AppColors.success),
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
