import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/export.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

/// Consulta ABIERTA de pedidos (`GET /app/orders/lookup`): cualquier rol puede
/// consultar cualquier pedido por su código o por la etiqueta de un producto,
/// tenga o no permiso para procesarlo. Es solo lectura.
class OrderLookupDataSource {
  const OrderLookupDataSource(this._ref);

  final Ref _ref;

  /// Pedidos que coinciden con [query] (código, etiqueta, cliente o documento).
  /// Sin coincidencias devuelve la lista vacía (el backend responde 404).
  Future<List<OrderLookupItem>> search(String query) async {
    try {
      final res = await _ref
          .read(logisticsApiProvider)
          .shipments
          .lookupOrders(q: query);
      return res.data;
    } on DioException catch (e) {
      final error = ApiException.fromDio(e);
      if (error.status == 404) return const <OrderLookupItem>[];
      throw error;
    }
  }
}

final orderLookupDataSourceProvider = Provider<OrderLookupDataSource>(
  OrderLookupDataSource.new,
);
