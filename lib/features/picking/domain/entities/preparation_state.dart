import 'package:flutter/foundation.dart';

/// Estado local del armado de un pedido en el andén.
///
/// Vive mientras la pantalla del pedido está montada (family por pedido). Lleva
/// qué unidades ya se prepararon y el carril/vehículo asignado para la carga.
/// Los escaneos reales se persisten vía la cola offline; esto es solo progreso UI.
@immutable
class PreparationState {
  const PreparationState({
    this.preparedUnitIds = const <String>{},
    this.vehicleId,
    this.lane,
  });

  /// Identidades de bulto (label_id) ya preparadas en esta sesión.
  final Set<String> preparedUnitIds;

  /// Vehículo/carril asignado para abrir la entrega al preparar.
  final String? vehicleId;

  /// Etiqueta legible del carril/posición de carga.
  final String? lane;

  bool get hasAssignment => vehicleId != null && vehicleId!.isNotEmpty;

  bool isPrepared(String unitId) => preparedUnitIds.contains(unitId);

  PreparationState copyWith({
    Set<String>? preparedUnitIds,
    String? vehicleId,
    String? lane,
  }) {
    return PreparationState(
      preparedUnitIds: preparedUnitIds ?? this.preparedUnitIds,
      vehicleId: vehicleId ?? this.vehicleId,
      lane: lane ?? this.lane,
    );
  }
}
