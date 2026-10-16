import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/assignment.dart';
import '../../../../core/api/models/carrier.dart';
import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/settlement.dart';
import '../../../../core/api/models/tariff.dart';
import '../../../../core/api/models/vehicle_class.dart';
import '../../domain/repositories/carrier_repository.dart';
import '../datasources/carrier_remote_data_source.dart';

/// Implementación del contrato del transportista: delega en el data source
/// remoto, que es quien habla con el cliente API.
class CarrierRepositoryImpl implements CarrierRepository {
  CarrierRepositoryImpl(this._remote);

  final CarrierRemoteDataSource _remote;

  @override
  Future<List<Carrier>> listCarriers() => _remote.listCarriers();

  @override
  Future<List<Settlement>> listSettlements(String carrierId) =>
      _remote.listSettlements(carrierId);

  @override
  Future<Settlement> getSettlement(String settlementId) =>
      _remote.getSettlement(settlementId);

  @override
  Future<void> approveSettlement(String settlementId) =>
      _remote.approveSettlement(settlementId);

  @override
  Future<void> disputeSettlement(String settlementId, String reason) =>
      _remote.disputeSettlement(settlementId, reason);

  @override
  Future<void> paySettlement(String settlementId, String paymentReference) =>
      _remote.paySettlement(settlementId, paymentReference);

  @override
  Future<Tariff> getTariff({
    required String carrierId,
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required VehicleClass vehicleClass,
  }) => _remote.getTariff(
    carrierId: carrierId,
    corridorFrom: corridorFrom,
    corridorTo: corridorTo,
    corridorType: corridorType,
    vehicleClass: vehicleClass,
  );

  @override
  Future<Assignment> assignForVolume({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required double volumeM3,
  }) => _remote.assignForVolume(
    corridorFrom: corridorFrom,
    corridorTo: corridorTo,
    corridorType: corridorType,
    volumeM3: volumeM3,
  );

  @override
  Future<Tariff> cheapestTariff({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
  }) => _remote.cheapestTariff(
    corridorFrom: corridorFrom,
    corridorTo: corridorTo,
    corridorType: corridorType,
  );
}

/// Provider del repositorio expuesto con el **tipo interfaz**: la presentación
/// y los casos de uso nunca ven la implementación concreta.
final carrierRepositoryProvider = Provider<CarrierRepository>(
  (ref) => CarrierRepositoryImpl(ref.watch(carrierRemoteDataSourceProvider)),
);
