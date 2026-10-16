import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/emitted_label.dart';
import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Query, CQRS): etiquetas ya emitidas de un pedido para preparar.
class GetOrderLabels {
  const GetOrderLabels(this._repo);

  final PickingRepository _repo;

  Future<List<EmittedLabel>> call(String orderNumber) =>
      _repo.getOrderLabels(orderNumber);
}

final getOrderLabelsProvider = Provider<GetOrderLabels>(
  (ref) => GetOrderLabels(ref.watch(pickingRepositoryProvider)),
);
