import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/emit_labels_request.dart';
import '../../../../core/api/models/emitted_label.dart';
import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Command, CQRS): emite el lote de etiquetas del pedido.
/// Propaga `ApiException` (incluye 409 si ya hay etiquetas vigentes).
class EmitLabels {
  const EmitLabels(this._repo);

  final PickingRepository _repo;

  Future<List<EmittedLabel>> call(String orderNumber, EmitLabelsRequest body) =>
      _repo.emitLabels(orderNumber, body);
}

final emitLabelsProvider = Provider<EmitLabels>(
  (ref) => EmitLabels(ref.watch(pickingRepositoryProvider)),
);

/// Caso de uso (Command, CQRS): emite las etiquetas del pedido POR ORDEN. El
/// backend deriva origen/destino/líneas del plan publicado; la app no pide nada
/// al usuario. Idempotente (reabrir emite lo que falte).
class EmitOrderLabels {
  const EmitOrderLabels(this._repo);

  final PickingRepository _repo;

  Future<List<EmittedLabel>> call(String orderNumber) =>
      _repo.emitOrderLabels(orderNumber);
}

final emitOrderLabelsProvider = Provider<EmitOrderLabels>(
  (ref) => EmitOrderLabels(ref.watch(pickingRepositoryProvider)),
);
