import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/api/models/reprint_labels_request.dart';
import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Command, CQRS): reimprime el lote, revocando las etiquetas
/// vigentes y emitiendo identidades nuevas (motivo obligatorio, ADR 004).
class ReprintLabels {
  const ReprintLabels(this._repo);

  final PickingRepository _repo;

  Future<List<EmittedLabel>> call(
    String orderNumber,
    ReprintLabelsRequest body,
  ) => _repo.reprintLabels(orderNumber, body);
}

final reprintLabelsProvider = Provider<ReprintLabels>(
  (ref) => ReprintLabels(ref.watch(pickingRepositoryProvider)),
);
