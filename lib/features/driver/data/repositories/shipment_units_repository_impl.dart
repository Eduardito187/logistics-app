import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../domain/repositories/shipment_units_repository.dart';
import '../datasources/shipment_units_data_source.dart';

/// Implementación del contrato de bultos del envío. Delega en el data source.
class ShipmentUnitsRepositoryImpl implements ShipmentUnitsRepository {
  const ShipmentUnitsRepositoryImpl(this._remote);

  final ShipmentUnitsDataSource _remote;

  @override
  Future<List<UnitTracking>> getShipmentUnits(String shipmentId) =>
      _remote.getShipmentUnits(shipmentId);
}

final shipmentUnitsRepositoryProvider = Provider<ShipmentUnitsRepository>(
  (ref) =>
      ShipmentUnitsRepositoryImpl(ref.watch(shipmentUnitsDataSourceProvider)),
);
