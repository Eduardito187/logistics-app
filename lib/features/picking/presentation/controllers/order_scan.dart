import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/labels/label_resolver.dart';
import '../../../../core/labels/signed_label.dart';
import '../../domain/entities/scanned_order.dart';
import '../../domain/order_number.dart';

/// Interpreta lo que el preparador escaneó para abrir un pedido.
///
/// Las etiquetas se imprimen POR PRODUCTO, así que lo natural es escanear la
/// etiqueta de cualquier producto y abrir SU pedido:
/// 1. QR firmado de una etiqueta → su `orderNumber` (viene en la etiqueta,
///    funciona sin señal).
/// 2. Code128 de una etiqueta (`label_id`) → el backend dice de qué pedido es.
/// 3. Número de pedido impreso en un documento → solo si tiene forma de pedido.
/// Cualquier otra cosa se rechaza con un aviso claro (nunca se navega con el
/// contenido crudo del código).
Future<ScannedOrder> orderFromScannedCode(WidgetRef ref, String raw) async {
  final code = raw.trim();
  if (code.isEmpty) {
    return const ScannedOrder.rejected('No se leyó ningún código.');
  }

  // 1. Etiqueta QR de un producto (JSON firmado).
  if (code.startsWith('{')) {
    try {
      final label = SignedLabel.fromQrContent(code);
      final order = label.payload.orderNumber.trim();
      if (isPlausibleOrderNumber(order)) return ScannedOrder.found(order);
    } on Object {
      // Cae al aviso de abajo.
    }
    return const ScannedOrder.rejected(
      'Esa etiqueta no es de DisTrack o está dañada.',
    );
  }

  // 2. Etiqueta Code128 → pedido según el backend.
  final resolution = await resolveLabelId(ref, code);
  final resolvedOrder = resolution?.orderNumber?.trim();
  if (resolution != null &&
      resolution.resolved &&
      resolvedOrder != null &&
      isPlausibleOrderNumber(resolvedOrder)) {
    return ScannedOrder.found(resolvedOrder);
  }

  // 3. Número de pedido (documento o tipeado).
  if (isPlausibleOrderNumber(code)) return ScannedOrder.found(code);

  return const ScannedOrder.rejected(
    'Ese código no es la etiqueta de un producto ni un número de pedido.',
  );
}
