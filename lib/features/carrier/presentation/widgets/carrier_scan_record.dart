import 'package:flutter/foundation.dart';

import '../../../../core/offline/submit_outcome.dart';

/// Un bulto registrado en la sesión actual (recojo o entrega), con el resultado
/// del envío offline-first para mostrarlo en la lista.
@immutable
class CarrierScanRecord {
  const CarrierScanRecord({
    required this.unitId,
    required this.title,
    required this.outcome,
    required this.at,
  });

  final String unitId;
  final String title;
  final SubmitOutcome outcome;
  final DateTime at;
}
