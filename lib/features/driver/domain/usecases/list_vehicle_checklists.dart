import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/datasources/fleet_data_source.dart';

/// Query (CQRS): historial de inspecciones diarias (checklists pre-salida) de un
/// vehículo, más reciente primero. La inspección pre-salida ES la inspección
/// diaria del camión.
class ListVehicleChecklists {
  const ListVehicleChecklists(this._dataSource);

  final FleetDataSource _dataSource;

  Future<List<PreTripChecklist>> call({required String vehicleId}) =>
      _dataSource.listVehicleChecklists(vehicleId: vehicleId);
}

final listVehicleChecklistsProvider = Provider<ListVehicleChecklists>(
  (ref) => ListVehicleChecklists(ref.watch(fleetDataSourceProvider)),
);
