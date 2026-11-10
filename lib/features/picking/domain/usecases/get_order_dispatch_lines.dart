import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/dispatch_lines_response.dart';
import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Query, CQRS): los productos a etiquetar de un pedido, ya
/// resueltos por el backend (nombre, SKU, foto, origen/destino por línea,
/// autorización y estado). Reemplaza la carga manual de origen/destino/líneas.
class GetOrderDispatchLines {
  const GetOrderDispatchLines(this._repo);

  final PickingRepository _repo;

  Future<DispatchLinesResponse> call(String orderNumber) =>
      _repo.getOrderDispatchLines(orderNumber);
}

final getOrderDispatchLinesProvider = Provider<GetOrderDispatchLines>(
  (ref) => GetOrderDispatchLines(ref.watch(pickingRepositoryProvider)),
);
