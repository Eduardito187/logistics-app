import '../../../../core/api/export.dart';

/// Contrato de la hoja de ruta del chofer y de las entregas de un vehículo
/// (módulo `execution` del backend). La capa `data` lo implementa; la
/// `presentation` sólo lo conoce a través de los casos de uso. Lanza
/// `ApiException` ante un error.
abstract interface class DriverRouteRepository {
  /// Ruta del día del vehículo en la fecha dada (paradas ordenadas).
  Future<DriverRoute> getDriverRoute({
    required String vehicleId,
    required DateTime date,
  });

  /// Entregas asignadas al vehículo (hoja de ruta de carga).
  Future<List<Delivery>> listVehicleDeliveries({required String vehicleId});

  /// Estado detallado de la entrega de un envío (status real + escaneos).
  Future<Delivery> getDeliveryState({required String shipmentId});

  /// Arma la ruta del día del vehículo a partir del plan publicado.
  Future<void> assembleDailyRoute({
    required String vehicleId,
    required DateTime date,
  });
}
