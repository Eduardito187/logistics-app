import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Query, CQRS): pedidos pendientes de preparar y cargar al camión.
///
/// Criterio: el preparador/andén trabaja los pedidos que ya llegaron pero
/// todavía no están sobre el camión → los estados previos a la ejecución:
/// `planned` (ya tiene ruta) y `received`. Se excluyen `inExecution`,
/// `delivered`, `failed`, `cancelled` y `$unknown`.
///
/// El filtro va en el servidor (un estado por consulta, en paralelo) y la
/// colección se pagina POR PÁGINA: antes se pedía la página 1 con 50 y el resto
/// **se perdía en silencio**. [call] trae una tanda y dice, por estado, si
/// quedan más, para que la pantalla pida la siguiente al llegar al final.
class ListOrdersToPrepare {
  const ListOrdersToPrepare(this._repo);

  final PickingRepository _repo;

  /// Estados que la worklist considera "por preparar/cargar".
  static const List<ShipmentStatus> toPrepareStatuses = [
    ShipmentStatus.planned,
    ShipmentStatus.received,
  ];

  /// Tamaño de tanda. Suficiente para llenar la pantalla sin bajar de más.
  static const int pageSize = 50;

  /// Trae una tanda. [pages] lleva la PRÓXIMA página por estado; un estado sin
  /// entrada ya se agotó y no se vuelve a pedir. En la primera llamada se pide
  /// la página 1 de todos.
  Future<OrdersToPrepareBatch> call({
    Map<ShipmentStatus, int> pages = const {},
  }) async {
    final pending = pages.isEmpty
        ? {for (final s in toPrepareStatuses) s: 1}
        : pages;
    if (pending.isEmpty) {
      return const OrdersToPrepareBatch(items: [], nextPages: {});
    }

    final results = await Future.wait([
      for (final entry in pending.entries)
        _repo
            .listShipments(
              status: entry.key,
              page: entry.value,
              perPage: pageSize,
            )
            .then(
              (page) => (
                status: entry.key,
                // Filtro defensivo por si el servidor ignora el parámetro.
                items: page.items
                    .where((s) => s.status == entry.key)
                    .toList(growable: false),
                nextPage: page.hasMore ? entry.value + 1 : null,
              ),
            ),
    ]);

    return OrdersToPrepareBatch(
      items: [for (final r in results) ...r.items],
      nextPages: {
        for (final r in results)
          if (r.nextPage != null) r.status: r.nextPage!,
      },
    );
  }
}

/// Una tanda de la worklist: los pedidos y la próxima página por estado.
class OrdersToPrepareBatch {
  const OrdersToPrepareBatch({required this.items, required this.nextPages});

  final List<Shipment> items;

  /// Próxima página por estado; un estado ausente ya se agotó.
  final Map<ShipmentStatus, int> nextPages;

  bool get hasMore => nextPages.isNotEmpty;
}

final listOrdersToPrepareProvider = Provider<ListOrdersToPrepare>(
  (ref) => ListOrdersToPrepare(ref.watch(pickingRepositoryProvider)),
);
