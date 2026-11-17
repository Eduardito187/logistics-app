import 'package:dio/dio.dart';

import '../api/export.dart';
import 'offline_queue.dart';

/// Mapa central de acciones offline → llamada real al cliente generado.
///
/// Cada feature encola con `OfflineQueue.submit(kind: ...)` usando una de estas
/// claves y `request.toJson()` como payload. Acá se reconstruye la request y se
/// ejecuta. Centralizar el reintento mantiene a los features desacoplados del
/// transporte.
///
/// Cada handler recibe el cliente generado [LogisticsApi] y un [Dio] directo:
/// casi todos usan el cliente; los endpoints cuyo contrato todavía no está en el
/// cliente generado (p. ej. motivos de fallida configurables) van por Dio.
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
  Dio dio,
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
  Dio dio,
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
  Dio dio,
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
  Dio dio,
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

/// Entrega fallida. `reason` viaja como **código** (string): puede ser un motivo
/// que creó el admin, fuera del enum generado. Por eso va por **Dio directo** y
/// no por el DTO del cliente (que tipa `reason` como enum y rechazaría un código
/// nuevo). La observación opcional viaja en `note`. Idempotencia por header
/// `Idempotency-Key` y también en el body (`idempotency_key`, que la cola ya
/// agregó al payload). Ver `docs/backend-requests/2026-11-17-motivos-de-no-
/// entrega-configurables-por-admin.md`.
Future<void> _recordFailedDelivery(
  LogisticsApi api,
  Dio dio,
  String key,
  Map<String, Object?> p,
) {
  return dio.post<Object?>(
    '/app/deliveries/failed',
    data: p,
    options: Options(headers: {'Idempotency-Key': key}),
  );
}

Future<void> _recordProofOfDelivery(
  LogisticsApi api,
  Dio dio,
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
  Dio dio,
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
  Dio dio,
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
  Dio dio,
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
  Dio dio,
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
  Dio dio,
  String key,
  Map<String, Object?> p,
) {
  return api.auth.updateDevicePushToken(
    body: AppDevicesCurrentPushTokenRequestBody.fromJson(p),
  );
}

Future<void> _recordNodeReception(
  LogisticsApi api,
  Dio dio,
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
  Dio dio,
  String key,
  Map<String, Object?> p,
) {
  return api.execution.receiveUnitAtNode(
    body: ReceiveUnitAtNodeRequest.fromJson(p),
    idempotencyKey: key,
  );
}
