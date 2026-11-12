import '../../../../core/api/export.dart';
import '../entities/due_maintenance_item.dart';

/// Contrato de operaciones de flota (módulo `fleetOps`): costos, utilización,
/// combustible, odómetro y mantenimiento del vehículo del chofer. La capa `data`
/// lo implementa; la `presentation` lo usa sólo vía casos de uso. Lanza
/// `ApiException` ante un error.
abstract interface class FleetOpsRepository {
  /// Resumen de costos (TCO + costo por km) del vehículo en un rango.
  Future<VehicleCostSummary> getVehicleCostSummary({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  });

  /// Utilización del vehículo en un rango, como mapa de métricas libre.
  Future<Map<String, Object?>> getVehicleUtilization({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  });

  /// Precio de combustible vigente para un tipo de combustible.
  Future<FuelPrice> getCurrentFuelPrice({required FuelType fuelType});

  /// Cargas de combustible del vehículo en el rango `[from, to]` (fechas de
  /// calendario, inclusive), más nuevas primero. El rango es obligatorio: sin
  /// él el backend devuelve el historial COMPLETO del camión.
  Future<List<Refuel>> listVehicleRefuels({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  });

  /// Lecturas de odómetro del vehículo en el rango `[from, to]` (fechas de
  /// calendario, inclusive), más nuevas primero. El rango es obligatorio por lo
  /// mismo que en [listVehicleRefuels].
  Future<List<OdometerReading>> listOdometerReadings({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  });

  /// Mantenimiento preventivo por vencer o vencido (más urgente primero).
  Future<List<DueMaintenanceItem>> listDueMaintenance();

  /// Registra una carga de combustible del vehículo. Devuelve el 202 del
  /// backend (`AcceptedEnvelope`): la carga se procesa de forma asíncrona.
  Future<AcceptedEnvelope> recordRefuel(RecordRefuelRequest request);

  /// Registra una lectura de odómetro del vehículo.
  Future<void> recordOdometer(RecordOdometerRequest request);
}
