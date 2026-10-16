import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command (CQRS) offline-first: reporta un incidente del vehículo (avería o
/// accidente). Pasa por la cola offline (`reportVehicleIncident`). El
/// `@vehicleId` viaja en el payload porque el endpoint lo lleva en la ruta.
class ReportVehicleIncident {
  const ReportVehicleIncident(this._queue);

  final OfflineQueue _queue;

  Future<SubmitOutcome> call({
    required String vehicleId,
    required Severity severity,
    required Type type,
    String? note,
    double? lat,
    double? lng,
    required DateTime occurredAt,
    required String label,
  }) {
    final payload = <String, Object?>{
      ...AppVehiclesVehicleIdIncidentsRequestBody(
        severity: severity,
        type: type,
        note: note,
        lat: lat,
        lng: lng,
        occurredAt: occurredAt,
      ).toJson(),
      '@vehicleId': vehicleId,
    };
    return _queue.submit(
      kind: 'reportVehicleIncident',
      payload: payload,
      label: label,
      occurredAt: occurredAt,
    );
  }
}

final reportVehicleIncidentProvider = Provider<ReportVehicleIncident>(
  (ref) => ReportVehicleIncident(ref.watch(offlineQueueProvider)),
);
