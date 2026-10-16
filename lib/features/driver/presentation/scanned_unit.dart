import '../../../core/offline/submit_outcome.dart';

/// Un bulto escaneado con el resultado de su registro offline-first.
class ScannedUnit {
  const ScannedUnit(this.unitId, this.outcome);

  final String unitId;
  final SubmitOutcome outcome;
}
