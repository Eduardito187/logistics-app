import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/driver_route_repository_impl.dart';
import '../repositories/driver_route_repository.dart';

/// Query (CQRS): detalle del envío de la parada en curso (teléfono del cliente
/// y productos a entregar).
class GetShipmentDetail {
  const GetShipmentDetail(this._repo);

  final DriverRouteRepository _repo;

  Future<Shipment> call({required String shipmentId}) =>
      _repo.getShipment(shipmentId: shipmentId);
}

final getShipmentDetailProvider = Provider<GetShipmentDetail>(
  (ref) => GetShipmentDetail(ref.watch(driverRouteRepositoryProvider)),
);
