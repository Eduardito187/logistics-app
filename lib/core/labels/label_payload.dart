/// Datos que viajan en el QR de una unidad de producto (tipo PKG), sin la firma.
///
/// Espejo de `LabelPayload` del backend (packages/logistics/labels). El mensaje
/// canónico tiene que coincidir byte a byte: lo vigila el vector de prueba compartido.
library;

import 'label_format_exception.dart';

/// "N de M": la unidad 1 de 2 del mismo producto, o la pieza (caja) 2 de 3.
class Fraction {
  Fraction(this.index, this.total) {
    if (total < 1 || total > 999) {
      throw LabelFormatException('total fuera de rango (1..999): $total');
    }
    if (index < 1 || index > total) {
      throw LabelFormatException('índice $index fuera de 1..$total');
    }
  }

  final int index;
  final int total;

  String toCanonical() => '$index/$total';

  @override
  bool operator ==(Object other) =>
      other is Fraction && other.index == index && other.total == total;

  @override
  int get hashCode => Object.hash(index, total);
}

/// Tipos de QR del ecosistema. Por ahora solo PKG tiene payload implementado.
enum LabelType {
  package('PKG'),
  manifest('MAN'),
  node('NOD'),
  vehicle('VEH'),
  delivery('DLV');

  const LabelType(this.code);

  final String code;

  static LabelType? fromCode(String code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

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
