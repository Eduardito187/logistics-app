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
import '../widgets/app_snack.dart';
import 'submit_outcome.dart';

/// Mensaje en español según el desenlace de un envío a la cola offline.
///
/// Offline invisible: lo encolado se informa igual que lo enviado. El usuario
/// no ve si hubo señal o no; la cola sube todo por debajo (ver `SyncNotice`).
String submitOutcomeMessage(SubmitOutcome outcome) => switch (outcome) {
  SubmitOutcome.sent || SubmitOutcome.queued => 'Registrado.',
  SubmitOutcome.failed => 'No se pudo registrar. Intentá de nuevo.',
};

/// Color semántico para teñir el aviso según el desenlace.
Color submitOutcomeColor(SubmitOutcome outcome) => switch (outcome) {
  SubmitOutcome.sent || SubmitOutcome.queued => AppColors.success,
  SubmitOutcome.failed => AppColors.danger,
};

/// Muestra el SnackBar del resultado de un envío offline-first, con el mensaje y
/// el color adecuados. Úsese tras `await queue.submit(...)`.
///
/// En pantallas con botón fijo al pie (escaneo seguido) pasar
/// `bottomClearance: kBottomActionClearance` para que el aviso no lo tape.
void showSubmitOutcome(
  BuildContext context,
  SubmitOutcome outcome, {
  double? bottomClearance,
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      buildAppSnackBar(
        submitOutcomeMessage(outcome),
        submitOutcomeColor(outcome),
        duration: outcome == SubmitOutcome.failed
            ? kErrorSnackDuration
            : kShortSnackDuration,
        bottomClearance: bottomClearance,
      ),
    );
}
