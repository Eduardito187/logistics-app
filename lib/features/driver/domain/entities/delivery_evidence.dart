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
    this.url,
  });

  /// Enlace temporal firmado (~2 h) a la imagen. Se abre con un GET simple,
  /// sin `Authorization`. No se guarda: si venció, se vuelve a pedir la lista.
  /// `null` con un backend anterior o si el archivo ya no existe.
  final String? url;

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
        url: _urlOrNull(json['url']),
      );

  /// Copia con otra [url] (al deduplicar se conserva una imagen visible).
  DeliveryEvidenceItem withUrl(String? url) => DeliveryEvidenceItem(
    id: id,
    kind: kind,
    status: status,
    detail: detail,
    url: url,
  );

  static String? _urlOrNull(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;
}
