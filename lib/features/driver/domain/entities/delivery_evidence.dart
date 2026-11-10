/// Estado de validación anti-fraude de una evidencia (lo resuelve el backend de
/// forma asíncrona; arranca en [pending]).
enum EvidenceValidation { pending, ok, review, mismatch, unknown }

EvidenceValidation evidenceValidationFromString(String? raw) => switch (raw) {
  'ok' => EvidenceValidation.ok,
  'review' => EvidenceValidation.review,
  'mismatch' => EvidenceValidation.mismatch,
  'pending' => EvidenceValidation.pending,
  _ => EvidenceValidation.unknown,
};

/// Una evidencia de entrega (firma, documento, foto) ligada al cliente, con su
/// estado de validación. Modelo mínimo para la UI (no es el DTO completo del
/// backend; se parsea del JSON crudo de `GET /app/deliveries/{id}/evidence`).
class DeliveryEvidenceItem {
  const DeliveryEvidenceItem({
    required this.id,
    required this.kind,
    required this.status,
    this.detail,
  });

  /// `pod` | `damage` | `signature` | `id_document`.
  final String kind;
  final String id;
  final EvidenceValidation status;
  final String? detail;

  factory DeliveryEvidenceItem.fromJson(Map<String, Object?> json) =>
      DeliveryEvidenceItem(
        id: '${json['id']}',
        kind: '${json['kind']}',
        status: evidenceValidationFromString(
          json['validation_status'] as String?,
        ),
        detail: json['validation_detail'] as String?,
      );
}
