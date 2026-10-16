import '../../../../core/api/models/assignment.dart';
import '../../../../core/api/models/carrier.dart';
import '../../../../core/api/models/corridor_type.dart';
import '../../../../core/api/models/settlement.dart';
import '../../../../core/api/models/tariff.dart';
import '../../../../core/api/models/vehicle_class.dart';

/// Contrato de acceso a datos del transportista. La capa de `data` lo
/// implementa; los casos de uso dependen de esta interfaz, no del cliente API.
abstract interface class CarrierRepository {
  /// Transportistas activos (para elegir el propio al entrar).
  Future<List<Carrier>> listCarriers();

  /// Liquidaciones del transportista elegido.
  Future<List<Settlement>> listSettlements(String carrierId);

  /// Detalle de una liquidación.
  Future<Settlement> getSettlement(String settlementId);

  /// Aprueba la liquidación (requiere red).
  Future<void> approveSettlement(String settlementId);

  /// Disputa la liquidación con un motivo (requiere red).
  Future<void> disputeSettlement(String settlementId, String reason);

  /// Marca la liquidación como pagada con una referencia (requiere red).
  Future<void> paySettlement(String settlementId, String paymentReference);

  /// Tarifa de un corredor para una clase de vehículo (solo lectura).
  Future<Tariff> getTariff({
    required String carrierId,
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required VehicleClass vehicleClass,
  });

  /// Sugiere la clase de vehículo y tarifa según el volumen (m³) del corredor.
  Future<Assignment> assignForVolume({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
    required double volumeM3,
  });

  /// Tarifa más barata disponible para un corredor (entre transportistas).
  Future<Tariff> cheapestTariff({
    required String corridorFrom,
    required String corridorTo,
    required CorridorType corridorType,
  });
}
