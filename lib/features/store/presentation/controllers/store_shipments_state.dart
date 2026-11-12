import '../../../../core/api/models/shipment.dart';

/// Lista acumulada de envíos del nodo más el estado del scroll infinito.
class StoreShipmentsState {
  const StoreShipmentsState({
    required this.shipments,
    required this.hasMore,
    this.loadingMore = false,
    this.moreFailed = false,
  });

  /// Todos los envíos traídos hasta ahora (página 1 + las que se fueron
  /// pidiendo al llegar al final de la lista).
  final List<Shipment> shipments;

  /// `true` si el servidor tiene más envíos para traer.
  final bool hasMore;

  /// `true` mientras se está trayendo la página siguiente (pie con spinner).
  final bool loadingMore;

  /// `true` si la última página pedida falló. El pie ofrece reintentar en vez
  /// de volver a pedirla solo (si no, el pie entraría en un bucle de GETs).
  final bool moreFailed;

  StoreShipmentsState copyWith({
    List<Shipment>? shipments,
    bool? hasMore,
    bool? loadingMore,
    bool? moreFailed,
  }) => StoreShipmentsState(
    shipments: shipments ?? this.shipments,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    moreFailed: moreFailed ?? this.moreFailed,
  );
}
