import 'package:flutter/foundation.dart';

/// Un escaneo del transportista que sigue en la cola offline del dispositivo
/// (todavía no subió). Es lo que se puede recuperar de una fila de la cola:
/// el producto, su SKU (de la etiqueta legible de la fila) y cuándo se escaneó.
@immutable
class QueuedCarrierScan {
  const QueuedCarrierScan({
    required this.unitId,
    required this.sku,
    required this.at,
  });

  final String unitId;
  final String sku;
  final DateTime at;
}
