import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/driver_route_repository_impl.dart';
import '../repositories/driver_route_repository.dart';

/// Query (CQRS): entregas asignadas al vehículo (hoja de ruta de carga).
class ListVehicleDeliveries {
  const ListVehicleDeliveries(this._repo);

  final DriverRouteRepository _repo;

  Future<List<Delivery>> call({required String vehicleId}) =>
      _repo.listVehicleDeliveries(vehicleId: vehicleId);
}

final listVehicleDeliveriesProvider = Provider<ListVehicleDeliveries>(
  (ref) => ListVehicleDeliveries(ref.watch(driverRouteRepositoryProvider)),
);
