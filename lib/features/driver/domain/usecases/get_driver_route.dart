import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/driver_route_repository_impl.dart';
import '../repositories/driver_route_repository.dart';

/// Query (CQRS): ruta del vehículo. SIN fecha = ruta ABIERTA del camión (de
/// cualquier día; midnight-safe), que es la vigente para operar. Con fecha, la
/// ruta de ese día puntual.
class GetDriverRoute {
  const GetDriverRoute(this._repo);

  final DriverRouteRepository _repo;

  Future<DriverRoute> call({
    required String vehicleId,
    DateTime? date,
  }) => _repo.getDriverRoute(vehicleId: vehicleId, date: date);
}

final getDriverRouteProvider = Provider<GetDriverRoute>(
  (ref) => GetDriverRoute(ref.watch(driverRouteRepositoryProvider)),
);
