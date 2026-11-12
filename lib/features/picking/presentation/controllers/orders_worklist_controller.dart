import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../domain/usecases/list_orders_to_prepare.dart';

/// Estado de la worklist del preparador con carga incremental.
class OrdersWorklistState {
  const OrdersWorklistState({
    this.orders = const [],
    this.nextPages = const {},
    this.loadingMore = false,
  });

  final List<Shipment> orders;

  /// Próxima página por estado; un estado ausente ya se agotó.
  final Map<ShipmentStatus, int> nextPages;

  /// Se está trayendo la tanda siguiente (la lista actual sigue visible).
  final bool loadingMore;

  /// Quedan pedidos por traer.
  bool get hasMore => nextPages.isNotEmpty;

  OrdersWorklistState copyWith({
    List<Shipment>? orders,
    Map<ShipmentStatus, int>? nextPages,
    bool? loadingMore,
  }) => OrdersWorklistState(
    orders: orders ?? this.orders,
    nextPages: nextPages ?? this.nextPages,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Worklist del preparador/andén con **scroll infinito**.
///
/// Antes era un `FutureProvider` que pedía la primera página de 50 por estado y
/// **descartaba el resto en silencio** (en staging hay 384 pedidos: se perdían
/// 334). Ahora trae tandas por página y la pantalla pide la siguiente al llegar
/// al final.
class OrdersWorklistNotifier extends AsyncNotifier<OrdersWorklistState> {
  @override
  Future<OrdersWorklistState> build() async {
    final batch = await ref.watch(listOrdersToPrepareProvider).call();
    return OrdersWorklistState(orders: batch.items, nextPages: batch.nextPages);
  }

  /// Trae la tanda siguiente y la agrega al final. No hace nada si ya no quedan
  /// o si hay una carga en curso (el scroll dispara seguido).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final batch = await ref
          .read(listOrdersToPrepareProvider)
          .call(pages: current.nextPages);
      // Sin duplicados: las páginas pueden solaparse si el servidor reordena.
      final seen = {for (final s in current.orders) s.id};
      final merged = [
        ...current.orders,
        for (final s in batch.items)
          if (seen.add(s.id)) s,
      ];
      state = AsyncData(
        OrdersWorklistState(orders: merged, nextPages: batch.nextPages),
      );
    } on Object {
      // Falló la tanda: se deja lo que ya estaba (no se vacía la lista).
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final ordersWorklistProvider =
    AsyncNotifierProvider<OrdersWorklistNotifier, OrdersWorklistState>(
      OrdersWorklistNotifier.new,
    );

/// Solo los pedidos de la worklist (las tandas ya cargadas), para quienes
/// necesitan la lista y no la paginación: widgets del inicio y la precarga.
/// La pantalla usa [ordersWorklistProvider] con su scroll infinito.
final ordersToPrepareProvider = FutureProvider.autoDispose<List<Shipment>>((
  ref,
) async {
  final state = await ref.watch(ordersWorklistProvider.future);
  return state.orders;
});
