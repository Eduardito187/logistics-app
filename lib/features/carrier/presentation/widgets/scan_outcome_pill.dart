import 'package:flutter/material.dart';

import '../../../../core/icons/icons.dart';
import '../../../../core/offline/submit_outcome.dart';
import '../../../../core/widgets/status_pill.dart';

/// Pastilla de estado de un registro de escaneo según su resultado de envío.
class ScanOutcomePill extends StatelessWidget {
  const ScanOutcomePill(this.outcome, {super.key});

  final SubmitOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (outcome) {
      SubmitOutcome.sent => ('Enviado', PillTone.success, AppIcon.cloudDone),
      // Offline invisible: lo encolado se ve como enviado.
      SubmitOutcome.queued => ('Enviado', PillTone.success, AppIcon.cloudDone),
      SubmitOutcome.failed => ('Error', PillTone.danger, AppIcon.error),
    };
    return StatusPill(label, tone: tone, icon: icon);
  }
}
