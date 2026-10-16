import '../api/export.dart';
import 'offline_queue.dart';

/// Mapa central de acciones offline → llamada real al cliente generado.
///
/// Cada feature encola con `OfflineQueue.submit(kind: ...)` usando una de estas
/// claves y `request.toJson()` como payload. Acá se reconstruye la request y se
/// ejecuta. Centralizar el reintento mantiene a los features desacoplados del
/// transporte.
///
/// Claves de path (vehículo, envío) viajan en el payload con prefijo `@`.
const Map<String, OfflineActionHandler> offlineHandlers = {
  // --- Preparador / andén ---
  'recordPreparationScan': _recordPreparationScan,
  // --- Chofer: carga, descarga, entrega ---
  'recordLoadScan': _recordLoadScan,
  'recordUnloadScan': _recordUnloadScan,
  'recordFailedDelivery': _recordFailedDelivery,
  'recordProofOfDelivery': _recordProofOfDelivery,
  'reportVehicleIncident': _reportVehicleIncident,
  'ingestTruckPosition': _ingestTruckPosition,
  // --- Tienda / nodos ---
  'recordNodeReception': _recordNodeReception,
  'receiveUnitAtNode': _receiveUnitAtNode,
};

Future<void> _recordPreparationScan(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  return api.execution.recordPreparationScan(
    body: PreparationScanRequest.fromJson(p),
    idempotencyKey: key,
  );
}

Future<void> _recordLoadScan(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  return api.execution.recordLoadScan(
    body: ScanRequest.fromJson(p),
    idempotencyKey: key,
  );
}

Future<void> _recordUnloadScan(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  return api.execution.recordUnloadScan(
    body: UnloadScanRequest.fromJson(p),
    idempotencyKey: key,
  );
}

Future<void> _recordFailedDelivery(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  return api.execution.recordFailedDelivery(
    body: FailedDeliveryRequest.fromJson(p),
    idempotencyKey: key,
  );
}

Future<void> _recordProofOfDelivery(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  return api.execution.recordProofOfDelivery(
    body: ProofOfDeliveryRequest.fromJson(p),
    idempotencyKey: key,
  );
}

Future<void> _reportVehicleIncident(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  final vehicleId = p['@vehicleId']! as String;
  return api.execution.reportVehicleIncident(
    vehicleId: vehicleId,
    body: AppVehiclesVehicleIdIncidentsRequestBody.fromJson(p),
    idempotencyKey: key,
  );
}

Future<void> _ingestTruckPosition(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  final shipmentId = p['@shipmentId']! as String;
  return api.tracking.ingestTruckPositionFromApp(
    shipmentId: shipmentId,
    body: TruckPositionInput.fromJson(p),
  );
}

Future<void> _recordNodeReception(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  return api.execution.recordNodeReception(
    body: NodeReceptionRequest.fromJson(p),
    idempotencyKey: key,
  );
}

Future<void> _receiveUnitAtNode(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  return api.execution.receiveUnitAtNode(
    body: ReceiveUnitAtNodeRequest.fromJson(p),
    idempotencyKey: key,
  );
}
