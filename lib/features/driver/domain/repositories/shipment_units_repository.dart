import '../../../../core/api/export.dart';

/// Contrato de los bultos esperados de un envío (módulo `tracking`). Lanza
/// `ApiException` ante un error.
abstract interface class ShipmentUnitsRepository {
  Future<List<UnitTracking>> getShipmentUnits(String shipmentId);
}
