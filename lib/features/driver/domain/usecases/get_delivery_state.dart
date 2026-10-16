import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/export.dart';
import '../../data/repositories/driver_route_repository_impl.dart';
import '../repositories/driver_route_repository.dart';

/// Query (CQRS): estado detallado de la entrega de un envío (status + escaneos).
class GetDeliveryState {
  const GetDeliveryState(this._repo);

  final DriverRouteRepository _repo;

  Future<Delivery> call({required String shipmentId}) =>
      _repo.getDeliveryState(shipmentId: shipmentId);
}

final getDeliveryStateProvider = Provider<GetDeliveryState>(
  (ref) => GetDeliveryState(ref.watch(driverRouteRepositoryProvider)),
);
