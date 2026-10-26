import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/shipment_units_repository_impl.dart';
import '../repositories/shipment_units_repository.dart';

/// Query (CQRS): bultos esperados de un envío (para validar la pertenencia de
/// cada bulto escaneado en la carga/descarga).
class GetShipmentUnits {
  const GetShipmentUnits(this._repo);

  final ShipmentUnitsRepository _repo;

  Future<List<UnitTracking>> call(String shipmentId) =>
      _repo.getShipmentUnits(shipmentId);
}

final getDriverShipmentUnitsProvider = Provider<GetShipmentUnits>(
  (ref) => GetShipmentUnits(ref.watch(shipmentUnitsRepositoryProvider)),
);
