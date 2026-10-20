import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../../../core/offline/offline_queue.dart';

/// Command (CQRS) offline-first: reporta un inconveniente de la entrega que NO
/// la cierra (demora, acceso restringido, el cliente pide esperar, dirección
/// confusa…). Pasa por la cola offline (`reportDeliveryIssue`); el id de la
/// acción viaja como `Idempotency-Key`.
class ReportDeliveryIssue {
  const ReportDeliveryIssue(this._queue);

  final OfflineQueue _queue;

  Future<SubmitOutcome> call({
    required String shipmentId,
    required DeliveryIssueType type,
    required DateTime occurredAt,
    String? note,
    double? lat,
    double? lng,
    required String label,
  }) {
    final trimmed = note?.trim();
    return _queue.submit(
      kind: 'reportDeliveryIssue',
      payload: {
        ...DeliveryIssueRequest(
          type: type,
          note: trimmed == null || trimmed.isEmpty ? null : trimmed,
          lat: lat,
          lng: lng,
          occurredAt: occurredAt,
        ).toJson(),
        // El envío va en el path del endpoint.
        '@shipmentId': shipmentId,
      },
      label: label,
      occurredAt: occurredAt,
    );
  }
}

final reportDeliveryIssueProvider = Provider<ReportDeliveryIssue>(
  (ref) => ReportDeliveryIssue(ref.watch(offlineQueueProvider)),
);
