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

  /// Deshace una marca optimista (el backend rechazó el escaneo).
  void unmarkPrepared(String unitId) {
    if (!state.preparedUnitIds.contains(unitId)) return;
    state = state.copyWith(
      preparedUnitIds: <String>{...state.preparedUnitIds}..remove(unitId),
    );
  }
}

/// SIN `autoDispose` a propósito: el progreso (unidades preparadas y carril)
/// no tiene endpoint de lectura y debe sobrevivir a salir y volver al pedido.
/// Es chico (un set de ids por pedido abierto en el turno).
final preparationControllerProvider =
    NotifierProvider.family<PreparationController, PreparationState, String>(
      (_) => PreparationController(),
    );
