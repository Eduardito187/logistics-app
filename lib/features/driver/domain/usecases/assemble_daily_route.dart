import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/driver_route_repository_impl.dart';
import '../repositories/driver_route_repository.dart';

/// Command (CQRS): arma la ruta del día del vehículo a partir del plan
/// publicado. Escritura directa a la red; propaga `ApiException` ante un error.
class AssembleDailyRoute {
  const AssembleDailyRoute(this._repo);

  final DriverRouteRepository _repo;

  Future<void> call({required String vehicleId, required DateTime date}) =>
      _repo.assembleDailyRoute(vehicleId: vehicleId, date: date);
}

final assembleDailyRouteProvider = Provider<AssembleDailyRoute>(
  (ref) => AssembleDailyRoute(ref.watch(driverRouteRepositoryProvider)),
);
