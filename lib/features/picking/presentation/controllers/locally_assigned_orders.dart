import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pedidos que el preparador YA asignó a un camión en ESTA sesión (por número de
/// pedido = `Shipment.externalId`).
///
/// El worklist "Pedidos por preparar" los oculta al instante (offline-invisible):
/// el backend todavía devuelve el envío como `PLANNED` aunque ya tenga entrega y
/// camión (su `status` NO avanza al asignar), así que sin esto el pedido
/// reaparecía en la lista aunque ya estaba asignado —"la lista nunca disminuye"—.
///
/// Es un alivio de UI de la sesión (se limpia al reiniciar la app). El arreglo
/// PERSISTENTE —que el backend saque el envío de `PLANNED` al asignar, o que la
/// lista excluya los que ya tienen entrega— va del lado del servidor.
class LocallyAssignedOrders extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Marca el pedido como asignado (idempotente).
  void markAssigned(String orderNumber) {
    if (state.contains(orderNumber)) return;
    state = {...state, orderNumber};
  }
}

final locallyAssignedOrdersProvider =
    NotifierProvider<LocallyAssignedOrders, Set<String>>(
      LocallyAssignedOrders.new,
    );
