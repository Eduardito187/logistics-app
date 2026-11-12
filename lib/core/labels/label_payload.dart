/// Datos que viajan en el QR de una unidad de producto (tipo PKG), sin la firma.
///
/// Espejo de `LabelPayload` del backend (packages/logistics/labels). El mensaje
/// canónico tiene que coincidir byte a byte: lo vigila el vector de prueba compartido.
library;

import 'fraction.dart';
import 'label_type.dart';

// Se reexportan [Fraction] y [LabelType] (movidos a su propio archivo por SRP)
// para no romper a quienes importan `labels/label_payload.dart`.
export 'fraction.dart';
export 'label_type.dart';

class LabelPayload {
  const LabelPayload({
    required this.version,
    required this.type,
    required this.keyId,
    required this.id,
    required this.orderNumber,
    required this.lineNumber,
    required this.sku,
    required this.unit,
    required this.piece,
    required this.origin,
    required this.destination,
    required this.issuedAt,
  });

  static const int currentVersion = 1;

  /// `keyId` reservado para la etiqueta ABIERTA (sin firma Ed25519): el backend
  /// emite con `k:0` cuando opera en modo abierto (`LABELS_OPEN`). Una etiqueta
  /// abierta NO se verifica criptográficamente; su autenticidad la decide el
  /// registro/pertenencia (que el `id` resuelva y pertenezca al envío/ruta). Así
  /// una etiqueta impresa nunca se descarta por un tema de claves.
  static const int openKeyId = 0;

  /// Destino "cliente final" (en vez de un código de nodo).
  static const String customerDestination = 'C';

  final int version;
  final LabelType type;
  final int keyId;
  final String id;
  final String orderNumber;
  final int lineNumber;
  final String sku;
  final Fraction unit;
  final Fraction piece;
  final String origin;
  final String destination;
  final int issuedAt;

  bool get isForCustomer => destination == customerDestination;

  /// Etiqueta ABIERTA (sin firma): se valida por registro/pertenencia, no por
  /// Ed25519. Ver [openKeyId].
  bool get isOpen => keyId == openKeyId;

  /// Mensaje exacto que se firma. Idéntico a `LabelPayload::canonical()` del backend.
  String canonical() => [
    'LGL',
    '$version',
    type.code,
    '$keyId',
    id,
    orderNumber,
    '$lineNumber',
    sku,
    unit.toCanonical(),
    piece.toCanonical(),
    origin,
    destination,
    '$issuedAt',
  ].join('|');
}
