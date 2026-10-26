import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/brand_loader.dart';

/// Utilidades compartidas para las escrituras con red del feature de ajustes:
/// ejecuta la acción mostrando un indicador de carga, convierte el error en un
/// SnackBar en español (vía `core/widgets/app_snack.dart`), invalida los
/// proveedores afectados y avisa del éxito.

/// Ejecuta [action] (que ya convierte `DioException` en [ApiException]) con un
/// diálogo de carga. Al terminar ejecuta [onSuccess] (para invalidar los
/// proveedores afectados) y muestra [success], o muestra el mensaje del error.
/// Devuelve `true` si la acción fue exitosa.
Future<bool> runSettingsAction(
  BuildContext context, {
  required Future<void> Function() action,
  required String success,
  VoidCallback? onSuccess,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: BrandLoader()),
    ),
  );
  try {
    await action();
    navigator.pop();
    onSuccess?.call();
    if (context.mounted) showSuccessSnack(context, success);
    return true;
  } on ApiException catch (e) {
    navigator.pop();
    if (context.mounted) showErrorSnack(context, e);
    return false;
  }
}

/// Pide confirmación para una acción sensible. Devuelve `true` si el usuario
/// confirma. [destructive] pinta el botón de confirmar en rojo.
Future<bool> confirmSettingsAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
