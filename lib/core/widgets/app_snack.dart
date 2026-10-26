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

/// Duración de los avisos de éxito/info: cortos para no tapar la pantalla en
/// flujos de escaneo seguidos (antes 4 s, el default de Flutter).
const Duration kShortSnackDuration = Duration(seconds: 2);

/// Los errores duran más: hay que leerlos.
const Duration kErrorSnackDuration = Duration(seconds: 4);

/// Margen inferior del aviso flotante cuando la pantalla tiene un botón de
/// acción fijo al pie (escanear, registrar): el aviso flota ENCIMA del botón y
/// no lo tapa. Pasarlo como `bottomClearance` en pantallas con barra inferior.
const double kBottomActionClearance = 96;

/// SnackBar verde de éxito para una escritura con red.
///
/// [bottomClearance]: ver [kBottomActionClearance].
void showSuccessSnack(
  BuildContext context,
  String message, {
  double? bottomClearance,
}) {
  _showSnack(
    context,
    message,
    AppColors.success,
    bottomClearance: bottomClearance,
  );
}

/// SnackBar rojo de error a partir de una excepción. Si es [ApiException] usa su
/// `.message` (mensaje corto en español ya listo para UI); si es un [String]
/// (validaciones locales) lo muestra tal cual; si no, un texto genérico.
///
/// Con [actionLabel] y [onAction] agrega un botón al aviso (p. ej. "Reintentar").
void showErrorSnack(
  BuildContext context,
  Object error, {
  String? actionLabel,
  VoidCallback? onAction,
  double? bottomClearance,
}) {
  final message = switch (error) {
    ApiException(:final message) => message,
    final String message => message,
    _ => 'Ocurrió un error.',
  };
  _showSnack(
    context,
    message,
    AppColors.danger,
    duration: kErrorSnackDuration,
    bottomClearance: bottomClearance,
    action: actionLabel != null && onAction != null
        ? SnackBarAction(
            label: actionLabel,
            textColor: Colors.white,
            onPressed: onAction,
          )
        : null,
  );
}

/// SnackBar azul informativo (avisos neutros, acciones "en proceso").
void showInfoSnack(
  BuildContext context,
  String message, {
  double? bottomClearance,
}) {
  _showSnack(
    context,
    message,
    AppColors.info,
    bottomClearance: bottomClearance,
  );
}

void _showSnack(
  BuildContext context,
  String message,
  Color color, {
  SnackBarAction? action,
  Duration duration = kShortSnackDuration,
  double? bottomClearance,
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      buildAppSnackBar(
        message,
        color,
        action: action,
        duration: duration,
        bottomClearance: bottomClearance,
      ),
    );
}

/// SnackBar flotante estándar de la app. Público para que los avisos propios
/// (p. ej. resultado de la cola offline) usen el mismo estilo y margen.
SnackBar buildAppSnackBar(
  String message,
  Color color, {
  SnackBarAction? action,
  Duration duration = kShortSnackDuration,
  double? bottomClearance,
}) {
  return SnackBar(
    content: Text(message, style: const TextStyle(fontSize: 15)),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    duration: duration,
    action: action,
    margin: bottomClearance == null
        ? null
        : EdgeInsets.fromLTRB(16, 0, 16, bottomClearance),
  );
}
