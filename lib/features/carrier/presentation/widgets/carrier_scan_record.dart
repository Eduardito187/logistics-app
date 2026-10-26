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

/// Bultos de la sesión que se muestran a la vez. Los escaneos ya quedaron en
/// la cola offline: la lista es solo feedback, así que en un turno de cientos
/// de bultos no hace falta guardarlos todos en memoria.
const int kMaxSessionRecords = 200;

/// Agrega [record] al principio de [records] (lo último arriba) y descarta los
/// más viejos por encima de [kMaxSessionRecords].
void addSessionRecord(
  List<CarrierScanRecord> records,
  CarrierScanRecord record,
) {
  records.insert(0, record);
  if (records.length > kMaxSessionRecords) {
    records.removeRange(kMaxSessionRecords, records.length);
  }
}
