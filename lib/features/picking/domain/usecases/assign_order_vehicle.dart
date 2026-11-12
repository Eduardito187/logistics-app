import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Command): asigna el pedido a un vehículo EN EL BACKEND.
///
/// Es lo que hace que el pedido deje de estar "por preparar": el backend lo
/// pone como parada de la ruta de ese camión. Antes la asignación era solo
/// estado local del app y el pedido seguía apareciendo en la worklist.
class AssignOrderVehicle {
  const AssignOrderVehicle(this._repo);

  final PickingRepository _repo;

  Future<void> call(String orderNumber, String vehicleId) =>
      _repo.assignVehicle(orderNumber, vehicleId);
}

final assignOrderVehicleProvider = Provider<AssignOrderVehicle>(
  (ref) => AssignOrderVehicle(ref.watch(pickingRepositoryProvider)),
);
