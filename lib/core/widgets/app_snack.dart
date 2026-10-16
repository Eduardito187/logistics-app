/// Helpers de SnackBar compartidos para TODA la app de campo.
///
/// Los features deben usar estas funciones en vez de reimplementar su propio
/// `showSuccessSnack` / `showErrorSnack` (hoy duplicados en varias pantallas,
/// p. ej. `driver/.../fleet_ops_common.dart`). Centralizan el color semántico
/// (desde [AppColors]) y el mapeo de errores de API a un mensaje en español.
///
/// Para el resultado de la cola offline (`SubmitOutcome`) usar
/// `showSubmitOutcome` (core/offline/submit_feedback.dart), no estas.
library;

import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// SnackBar verde de éxito para una escritura con red.
void showSuccessSnack(BuildContext context, String message) {
  _showSnack(context, message, AppColors.success);
}

/// SnackBar rojo de error a partir de una excepción. Si es [ApiException] usa su
/// `.message` (mensaje corto en español ya listo para UI); si no, un texto
/// genérico.
void showErrorSnack(BuildContext context, Object error) {
  final message = error is ApiException ? error.message : 'Ocurrió un error.';
  _showSnack(context, message, AppColors.danger);
}

/// SnackBar azul informativo (avisos neutros, acciones "en proceso").
void showInfoSnack(BuildContext context, String message) {
  _showSnack(context, message, AppColors.info);
}

void _showSnack(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 15)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
