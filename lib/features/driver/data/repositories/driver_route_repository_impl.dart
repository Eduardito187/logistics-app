import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../domain/repositories/driver_route_repository.dart';
import '../datasources/driver_route_data_source.dart';

/// Implementación del contrato de ruta/entregas. Delega en el data source y, en
/// `assembleDailyRoute`, arma el cuerpo del pedido (el backend ensambla desde el
/// plan publicado, por eso no se envían paradas manuales).
class DriverRouteRepositoryImpl implements DriverRouteRepository {
  const DriverRouteRepositoryImpl(this._remote);

  final DriverRouteDataSource _remote;

  @override
  Future<DriverRoute> getDriverRoute({
    required String vehicleId,
    required DateTime date,
  }) => _remote.getDriverRoute(vehicleId: vehicleId, date: date);

  @override
  Future<List<Delivery>> listVehicleDeliveries({required String vehicleId}) =>
      _remote.listVehicleDeliveries(vehicleId: vehicleId);

  @override
  Future<Delivery> getDeliveryState({required String shipmentId}) =>
      _remote.getDeliveryState(shipmentId: shipmentId);

  @override
  Future<void> assembleDailyRoute({
    required String vehicleId,
    required DateTime date,
  }) => _remote.assembleDailyRoute(
    vehicleId: vehicleId,
    body: AppVehiclesVehicleIdRouteRequestBody(
      routeDate: date,
      stops: const <Stops>[],
    ),
  );
}

final driverRouteRepositoryProvider = Provider<DriverRouteRepository>(
  (ref) => DriverRouteRepositoryImpl(ref.watch(driverRouteDataSourceProvider)),
);
