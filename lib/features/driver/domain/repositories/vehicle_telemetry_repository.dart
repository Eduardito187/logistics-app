import '../../../../core/api/export.dart';

/// Contrato de telemetría a nivel vehículo (módulo `telemetry`): despacho en
/// lote de posiciones GPS del camión. La capa `data` lo implementa; la
/// `presentation` lo usa sólo vía casos de uso. Lanza `ApiException` ante error.
abstract interface class VehicleTelemetryRepository {
  /// Envía un lote de posiciones GPS del vehículo.
  Future<void> recordVehiclePings({
    required String vehicleId,
    required List<VehiclePing> pings,
  });
}
