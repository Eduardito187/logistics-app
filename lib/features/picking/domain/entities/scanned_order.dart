/// Resultado de interpretar un código escaneado (o tipeado) para abrir un
/// pedido en preparación: el número de pedido, o el motivo para el operario.
class ScannedOrder {
  const ScannedOrder.found(String this.orderNumber) : error = null;

  const ScannedOrder.rejected(String this.error) : orderNumber = null;

  /// Número de pedido a abrir (`null` si se rechazó).
  final String? orderNumber;

  /// Aviso en español para el operario (`null` si se encontró el pedido).
  final String? error;

  bool get isFound => orderNumber != null;
}
