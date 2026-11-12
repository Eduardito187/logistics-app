import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/usecases/list_shipments.dart';
import 'selected_store_node_notifier.dart';
import 'store_shipments_state.dart';

/// Envíos por página. 50 es el default del backend y llena de sobra la primera
/// pantalla; con más filas se gasta red y RAM en tarjetas que nadie mira.
const int kStoreShipmentsPageSize = 50;

/// Lista paginada de envíos que llegan a la tienda del usuario (recepción y
/// recojo en mostrador comparten este estado).
///
/// - Filtro en el servidor por `destination_node_id` = tienda de la sesión.
/// - Página 1 al construirse; [loadMore] agrega la siguiente al llegar al final
///   de la lista (antes solo existían los primeros 50 envíos y el resto se
///   perdía en silencio).
/// - Caché corta: ir de Recepción a Recojo (o volver de un detalle) muestra la
///   lista al instante, con las páginas ya traídas, sin spinner ni otro GET.
/// - Refrescar = invalidar el provider: vuelve a la página 1 (lo que espera el
///   gesto de "tirar para refrescar").
class StoreShipmentsNotifier extends AsyncNotifier<StoreShipmentsState> {
  /// Última página pedida con éxito.
  int _page = 1;

  /// Tienda de la que son las páginas acumuladas.
  String? _nodeId;

  /// Sube con cada reconstrucción (cambio de tienda o refresco): una página en
  /// vuelo de una generación anterior ya no corresponde a lo que se ve.
  int _generation = 0;

  @override
  Future<StoreShipmentsState> build() async {
    ref.cacheFor(CacheTtl.short);
    final nodeId = ref.watch(selectedStoreNodeProvider.select((n) => n?.id));
    // Cambió la tienda: el acumulado anterior no sirve, se arranca de cero.
    _nodeId = nodeId;
    _page = 1;
    _generation++;
    final first = await ref
        .watch(listShipmentsProvider)
        .call(
          destinationNodeId: nodeId,
          page: 1,
          perPage: kStoreShipmentsPageSize,
        );
    return StoreShipmentsState(
      shipments: first.shipments,
      hasMore: first.hasMore,
    );
  }

  /// Trae la página siguiente y la agrega al final. No hace nada si todavía no
  /// hay primera página, si ya se trajo todo o si hay una página en vuelo.
  Future<void> loadMore() async {
    // El provider es autoDispose: puede haberse liberado (salir de la pantalla)
    // entre el gesto y este punto, y tocar `state` ahí lanza.
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    if (!current.hasMore || current.loadingMore) return;
    final nodeId = _nodeId;
    final generation = _generation;
    final next = _page + 1;
    state = AsyncData(current.copyWith(loadingMore: true, moreFailed: false));
    try {
      final page = await ref
          .read(listShipmentsProvider)
          .call(
            destinationNodeId: nodeId,
            page: next,
            perPage: kStoreShipmentsPageSize,
          );
      // Se liberó el provider, cambió la tienda o se refrescó mientras llegaba
      // la página: se descarta en vez de mezclarla con otra lista.
      if (!ref.mounted || _generation != generation) return;
      final latest = state.value;
      if (latest == null) return;
      _page = next;
      state = AsyncData(
        latest.copyWith(
          shipments: _append(latest.shipments, page.shipments),
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on Object {
      // Falló la página: se conserva lo ya visible y el pie ofrece reintentar.
      if (!ref.mounted || _generation != generation) return;
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(latest.copyWith(loadingMore: false, moreFailed: true));
    }
  }

  /// Agrega [page] a [current] salteando los envíos que ya están: entre dos
  /// GETs la bandeja pudo moverse y una fila repetida se vería dos veces.
  List<Shipment> _append(List<Shipment> current, List<Shipment> page) {
    final ids = {for (final shipment in current) shipment.id};
    return [
      ...current,
      for (final shipment in page)
        if (ids.add(shipment.id)) shipment,
    ];
  }
}

final storeShipmentsPagedProvider =
    AsyncNotifierProvider.autoDispose<
      StoreShipmentsNotifier,
      StoreShipmentsState
    >(StoreShipmentsNotifier.new);
