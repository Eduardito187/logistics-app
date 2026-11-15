/// Tipo de mantenimiento al mandar un camión al taller.
enum MaintenanceType {
  corrective('corrective', 'Correctivo (falla)'),
  preventive('preventive', 'Preventivo'),
  inspection('inspection', 'Inspección');

  const MaintenanceType(this.wire, this.label);

  final String wire;
  final String label;
}

/// Resultado de mandar un camión a mantenimiento.
///
/// El backend abre la orden y deja el camión en mantenimiento. Si tenía
/// paradas pendientes en su ruta: o se pasaron a otro camión
/// ([reassignedCount]), o quedaron LIBERADAS ([pendingOrders]) esperando que el
/// administrador las asigne. Las ya atendidas no se tocan.
class MaintenanceResult {
  const MaintenanceResult({
    this.reassignedCount = 0,
    this.pendingOrders = const [],
  });

  /// Pedidos que pasaron al otro camión.
  final int reassignedCount;

  /// Pedidos que quedaron sin camión (referencia legible de cada uno).
  final List<String> pendingOrders;

  bool get hasPendingOrders => pendingOrders.isNotEmpty;
}
