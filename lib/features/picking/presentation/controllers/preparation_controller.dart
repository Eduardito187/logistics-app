import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/preparation_state.dart';

/// Progreso de armado por pedido (qué unidades se prepararon y el carril).
/// Estado de UI puro; los escaneos reales se persisten vía la cola offline.
class PreparationController extends Notifier<PreparationState> {
  @override
  PreparationState build() => const PreparationState();

  /// Asigna el vehículo/carril con el que se abrirá la entrega al preparar.
  void assign({required String vehicleId, String? lane}) {
    state = state.copyWith(vehicleId: vehicleId, lane: lane);
  }

  /// Marca una unidad como preparada (idempotente en la UI).
  void markPrepared(String unitId) {
    if (state.preparedUnitIds.contains(unitId)) return;
    state = state.copyWith(
      preparedUnitIds: <String>{...state.preparedUnitIds, unitId},
    );
  }
}

final preparationControllerProvider =
    NotifierProvider.family<PreparationController, PreparationState, String>(
      (_) => PreparationController(),
    );
