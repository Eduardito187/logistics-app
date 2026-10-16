import 'package:flutter/material.dart';

import '../../../../core/offline/submit_outcome.dart';
import '../../../../core/widgets/status_pill.dart';

/// Pastilla de estado de un registro de escaneo según su resultado de envío.
class ScanOutcomePill extends StatelessWidget {
  const ScanOutcomePill(this.outcome, {super.key});

  final SubmitOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (outcome) {
      SubmitOutcome.sent => ('Enviado', PillTone.success, Icons.cloud_done),
      // Offline invisible: lo encolado se ve como enviado.
      SubmitOutcome.queued => ('Enviado', PillTone.success, Icons.cloud_done),
      SubmitOutcome.failed => ('Error', PillTone.danger, Icons.error_outline),
    };
    return StatusPill(label, tone: tone, icon: icon);
  }
}
