import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/labels/label_format_exception.dart';
import '../../../core/labels/label_resolver.dart';
import '../../../core/labels/signed_label.dart';

/// Por qué no se pudo leer una etiqueta en "Recojo en tienda".
enum PickupLabelProblem {
  /// Code128 sin señal: no se puede consultar al backend.
  unreachable,

  /// El backend no reconoce esa etiqueta.
  unknown,
}

/// Lo que dice una etiqueta escaneada sobre su pedido: nº de pedido, producto y
/// (si vino por el backend) el envío. Con esto la tienda sabe de qué pedido es
/// un producto que tiene en su almacén.
class PickupLabelInfo {
  const PickupLabelInfo({
    this.orderNumber,
    this.shipmentId,
    this.sku,
    this.productName,
    this.customerName,
    this.customerDocumentId,
    this.customerPhone,
    this.problem,
  });

  const PickupLabelInfo.failed(PickupLabelProblem this.problem)
    : orderNumber = null,
      shipmentId = null,
      sku = null,
      productName = null,
      customerName = null,
      customerDocumentId = null,
      customerPhone = null;

  /// Cliente del pedido según el backend (solo por Code128; `null` si no vino).
  final String? customerName;
  final String? customerDocumentId;
  final String? customerPhone;

  final String? orderNumber;
  final String? shipmentId;
  final String? sku;
  final String? productName;

  /// `null` si la etiqueta se pudo leer.
  final PickupLabelProblem? problem;
}

/// Lee una etiqueta escaneada. El **QR** trae el pedido y el SKU en su contenido
/// (sin red, sin llamada); el **Code128** (su valor es el `label_id`) se
/// resuelve contra el backend con el endpoint que ya usa el escaneo de
/// productos. Nunca lanza.
Future<PickupLabelInfo> lookupPickupLabel(WidgetRef ref, String code) async {
  try {
    final payload = SignedLabel.fromQrContent(code).payload;
    return PickupLabelInfo(orderNumber: payload.orderNumber, sku: payload.sku);
  } on LabelFormatException {
    // No es un QR de etiqueta → Code128.
  }
  final res = await resolveLabelId(ref, code);
  if (res == null) {
    return const PickupLabelInfo.failed(PickupLabelProblem.unreachable);
  }
  if (!res.resolved) {
    return const PickupLabelInfo.failed(PickupLabelProblem.unknown);
  }
  return PickupLabelInfo(
    orderNumber: res.orderNumber,
    shipmentId: res.shipmentId,
    sku: res.sku,
    productName: res.productName,
    customerName: res.customerName,
    customerDocumentId: res.customerDocumentId,
    customerPhone: res.customerPhone,
  );
}
