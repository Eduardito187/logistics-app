import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../../../core/auth/session.dart';
import '../../domain/usecases/list_orders_to_prepare.dart';
import '../../../../core/realtime/realtime_bus.dart';
import '../../../../core/realtime/realtime_refresh.dart';
import 'locally_assigned_orders.dart';

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
    // La lista es de QUIEN está logueado. Este provider no es autoDispose (se
    // precarga en el inicio y conserva el scroll), así que sin esto sobrevivía
    // al cierre de sesión: al entrar con otro usuario en el mismo teléfono se
    // veía la lista (o el vacío) del anterior hasta refrescar a mano. Se
    // observa el usuario y el rol, no el token (que rota al renovarse).
    ref.watch(sessionProvider.select((s) => (s?.userName, s?.role)));
    // Ciudad del preparador: con ella se descartan pedidos de OTRA ciudad que
    // el backend no haya scopeado (cuenta sin ciudad asignada → fail-open).
    final city = ref.watch(sessionProvider.select((s) => s?.city));
    // EN TIEMPO REAL: un plan publicado, un pedido nuevo o lo que preparó
    // otro preparador actualiza la lista sola.
    ref.refreshOnRealtime(RealtimeTopic.picking, const {'picking.updated'});
    // Se ocultan los pedidos ya asignados en esta sesión (el backend aún los
    // devuelve como PLANNED; ver [LocallyAssignedOrders]). `watch`: al asignar
    // uno, la lista se recalcula sola y el pedido desaparece al instante.
    final assigned = ref.watch(locallyAssignedOrdersProvider);
    final batch = await ref.watch(listOrdersToPrepareProvider).call();
    return OrdersWorklistState(
      orders: _scoped(batch.items, assigned, city),
      nextPages: batch.nextPages,
    );
  }

  /// Deja la tanda lista para mostrar: sin los pedidos ya asignados en esta
  /// sesión, sin los que YA preparó cualquiera (según el backend) y sin los que
  /// claramente son de otra ciudad.
  static List<Shipment> _scoped(
    List<Shipment> items,
    Set<String> assigned,
    String? city,
  ) {
    final myCity = _norm(city);
    return [
      for (final s in items)
        if (!assigned.contains(s.externalId) &&
            !_alreadyHandled(s) &&
            _inMyCity(s, myCity))
          s,
    ];
  }

  /// ¿El pedido ya salió de la bandeja del preparador porque YA se preparó/cargó/
  /// entregó? Lo dice el backend en `progress` (`prepared_at` queda seteado al
  /// asignar el vehículo, que en el flujo vigente ES preparar). Durable y entre
  /// reinicios, a diferencia del "asignado local" de sesión. NO oculta un pedido
  /// solo pre-asignado por un plan publicado (ese trae `vehicleId` pero
  /// `preparedAt == null`): el preparador todavía debe prepararlo.
  static bool _alreadyHandled(Shipment s) {
    final p = s.progress;
    if (p == null) return false;
    return p.preparedAt != null || p.loadedAt != null || p.deliveredAt != null;
  }

  /// ¿El pedido es de la ciudad del preparador? Se descarta SOLO cuando se sabe
  /// la ciudad del usuario Y el origen del pedido Y son distintas. Si cualquiera
  /// es desconocido se muestra (no se oculta un pedido legítimo por falta de
  /// dato): mismo criterio fail-open que el backend.
  static bool _inMyCity(Shipment s, String? myCity) {
    if (myCity == null) return true;
    final origin = _norm(s.originDepartment);
    if (origin == null) return true;
    return origin == myCity;
  }

  static String? _norm(String? v) {
    final t = v?.trim().toLowerCase();
    return (t == null || t.isEmpty) ? null : t;
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
      final assigned = ref.read(locallyAssignedOrdersProvider);
      final myCity = _norm(ref.read(sessionProvider)?.city);
      // Sin duplicados: las páginas pueden solaparse si el servidor reordena.
      final seen = {for (final s in current.orders) s.id};
      final merged = [
        ...current.orders,
        for (final s in batch.items)
          if (!assigned.contains(s.externalId) &&
              !_alreadyHandled(s) &&
              _inMyCity(s, myCity) &&
              seen.add(s.id))
            s,
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
