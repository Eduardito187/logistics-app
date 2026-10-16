/// Feedback de UI compartido para el resultado de la cola offline-first.
///
/// Traduce un [SubmitOutcome] (lo que devuelve `OfflineQueue.submit`) a un
/// SnackBar con mensaje en español y color semántico. Los features deben usar
/// `showSubmitOutcome` en vez de reimplementar su propio `showOutcome` /
/// `submitOutcomeMessage` / `showFieldSnack` / `showSubmitFeedback` (hoy
/// duplicados en store, driver y carrier).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'submit_outcome.dart';

/// Mensaje en español según el desenlace de un envío a la cola offline.
String submitOutcomeMessage(SubmitOutcome outcome) => switch (outcome) {
  SubmitOutcome.sent => 'Registrado y enviado.',
  SubmitOutcome.queued =>
    'Guardado sin conexión. Se enviará al recuperar señal.',
  SubmitOutcome.failed => 'No se pudo registrar. Revísalo en Sincronización.',
};

/// Color semántico para teñir el aviso según el desenlace.
Color submitOutcomeColor(SubmitOutcome outcome) => switch (outcome) {
  SubmitOutcome.sent => AppColors.success,
  SubmitOutcome.queued => AppColors.warning,
  SubmitOutcome.failed => AppColors.danger,
};

/// Muestra el SnackBar del resultado de un envío offline-first, con el mensaje y
/// el color adecuados. Úsese tras `await queue.submit(...)`.
void showSubmitOutcome(BuildContext context, SubmitOutcome outcome) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          submitOutcomeMessage(outcome),
          style: const TextStyle(fontSize: 15),
        ),
        backgroundColor: submitOutcomeColor(outcome),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
