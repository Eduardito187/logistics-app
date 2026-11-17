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
  'recordStoreDrop': _recordStoreDrop,
  'recordFailedDelivery': _recordFailedDelivery,
  'recordProofOfDelivery': _recordProofOfDelivery,
  'reportVehicleIncident': _reportVehicleIncident,
  'ingestTruckPosition': _ingestTruckPosition,
  'recordVehiclePings': _recordVehiclePings,
  'reportDeliveryIssue': _reportDeliveryIssue,
  // --- Push ---
  'updateDevicePushToken': _updateDevicePushToken,
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

/// El chofer deja el pedido en la tienda. El envío va en el path (`@shipmentId`
/// en el payload); el resto del payload es el body.
Future<void> _recordStoreDrop(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  final shipmentId = p['@shipmentId']! as String;
  return api.execution.recordStoreDrop(
    shipmentId: shipmentId,
    body: AppDeliveriesShipmentIdStoreDropRequestBody.fromJson({
      for (final entry in p.entries)
        if (!entry.key.startsWith('@')) entry.key: entry.value,
    }),
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

/// Posición GPS del camión por el camino de TELEMETRÍA (lote), que es el único
/// que alimenta el motor de desvío/reruteo del backend (el endpoint por-envío
/// solo deja la miga de pan; `/telemetry/pings` hace fan-out a tracking Y
/// dispara el off-route). El vehículo va en `@vehicleId` (requerido); la ruta y
/// el chofer, opcionales, en `@routeId`/`@driverId`. El resto del payload es el
/// `VehiclePing`. Idempotencia por `fix_id` del ping (no por Idempotency-Key: el
/// endpoint no lo lleva). Se manda un ping por fila (cada fila = un POST de la
/// cola), dentro de un lote de 1.
Future<void> _recordVehiclePings(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  final vehicleId = p['@vehicleId']! as String;
  final ping = VehiclePing.fromJson({
    for (final entry in p.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value,
  });
  return api.telemetry.recordAppVehiclePings(
    body: AppTelemetryPingsRequestBody(
      vehicleId: vehicleId,
      routeId: p['@routeId'] as String?,
      driverId: p['@driverId'] as String?,
      pings: [ping],
    ),
  );
}

/// Inconveniente de la entrega que NO la cierra (demora, acceso…). El envío va
/// en el path: se guarda como `@shipmentId` en el payload.
Future<void> _reportDeliveryIssue(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  final shipmentId = p['@shipmentId']! as String;
  return api.execution.reportDeliveryIssue(
    shipmentId: shipmentId,
    body: DeliveryIssueRequest.fromJson(p),
    idempotencyKey: key,
  );
}

/// Identificador push (FID de FCM) del dispositivo actual; `null` = baja.
/// PUT idempotente por naturaleza: no lleva clave.
Future<void> _updateDevicePushToken(
  LogisticsApi api,
  String key,
  Map<String, Object?> p,
) {
  return api.auth.updateDevicePushToken(
    body: AppDevicesCurrentPushTokenRequestBody.fromJson(p),
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
