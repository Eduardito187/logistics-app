import 'package:flutter/foundation.dart';

/// Datos útiles de una etiqueta verificada.
@immutable
class SignedLabelResult {
  const SignedLabelResult({
    required this.unitId,
    required this.shipmentId,
    required this.sku,
  });

  /// `LabelPayload.id`: identifica el bulto escaneado (`unit_id`).
  final String unitId;

  /// `LabelPayload.orderNumber`: referencia del envío/pedido (`shipment_id`).
  final String shipmentId;
  final String sku;
}
