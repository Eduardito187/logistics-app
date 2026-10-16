import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/driver_route_repository_impl.dart';
import '../repositories/driver_route_repository.dart';

/// Query (CQRS): ruta del día del vehículo en una fecha.
class GetDriverRoute {
  const GetDriverRoute(this._repo);

  final DriverRouteRepository _repo;

  Future<DriverRoute> call({
    required String vehicleId,
    required DateTime date,
  }) => _repo.getDriverRoute(vehicleId: vehicleId, date: date);
}

final getDriverRouteProvider = Provider<GetDriverRoute>(
  (ref) => GetDriverRoute(ref.watch(driverRouteRepositoryProvider)),
);
