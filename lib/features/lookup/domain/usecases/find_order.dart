import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/order_lookup_data_source.dart';

/// Query: el pedido que corresponde a un código (el primero que coincide), o
/// `null` si no existe. Usa la consulta abierta de pedidos.
class FindOrder {
  const FindOrder(this._source);

  final OrderLookupDataSource _source;

  Future<OrderLookupItem?> call(String code) async {
    final found = await _source.search(code.trim());
    for (final item in found) {
      if (item.externalId.toLowerCase() == code.trim().toLowerCase()) {
        return item;
      }
    }
    return found.isEmpty ? null : found.first;
  }
}

final findOrderProvider = Provider<FindOrder>(
  (ref) => FindOrder(ref.watch(orderLookupDataSourceProvider)),
);
