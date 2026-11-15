// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_deliveries_shipment_id_store_drop_request_body.dart';
import '../models/app_orders_order_number_vehicle_request_body.dart';
import '../models/app_vehicles_vehicle_id_incidents_request_body.dart';
import '../models/app_vehicles_vehicle_id_route_request_body.dart';
import '../models/assign_shelf_location_request.dart';
import '../models/delivery_evidence_collection.dart';
import '../models/delivery_issue_request.dart';
import '../models/enum0.dart';
import '../models/enum1.dart';
import '../models/failed_delivery_request.dart';
import '../models/get_app_deliveries_shipment_id_response.dart';
import '../models/get_app_node_receptions_response.dart';
import '../models/get_app_node_receptions_shipment_id_node_id_response.dart';
import '../models/get_app_vehicles_vehicle_id_deliveries_response.dart';
import '../models/get_app_vehicles_vehicle_id_route_response.dart';
import '../models/integrations_evidence_evidence_id_validation_request_body.dart';
import '../models/node_reception_request.dart';
import '../models/open_node_reception_request.dart';
import '../models/post_app_deliveries_failed_response.dart';
import '../models/post_app_deliveries_photos_response.dart';
import '../models/post_app_deliveries_proof_of_delivery_response.dart';
import '../models/post_app_deliveries_scans_load_response.dart';
import '../models/post_app_deliveries_scans_node_reception_response.dart';
import '../models/post_app_deliveries_scans_preparation_response.dart';
import '../models/post_app_deliveries_scans_unload_response.dart';
import '../models/post_app_deliveries_shipment_id_arrived_response.dart';
import '../models/post_app_deliveries_shipment_id_complete_response.dart';
import '../models/post_app_deliveries_shipment_id_issues_response.dart';
import '../models/post_app_deliveries_shipment_id_store_drop_response.dart';
import '../models/post_app_labels_verify_response.dart';
import '../models/post_app_node_receptions_reconcile_response.dart';
import '../models/post_app_node_receptions_response.dart';
import '../models/post_app_node_receptions_shipment_id_units_location_response.dart';
import '../models/post_app_node_receptions_shipment_id_units_unit_id_location_response.dart';
import '../models/post_app_node_receptions_units_response.dart';
import '../models/post_app_orders_order_number_vehicle_response.dart';
import '../models/post_app_vehicles_vehicle_id_incidents_response.dart';
import '../models/post_app_vehicles_vehicle_id_route_close_response.dart';
import '../models/post_app_vehicles_vehicle_id_route_response.dart';
import '../models/post_app_vehicles_vehicle_id_route_start_response.dart';
import '../models/post_integrations_evidence_evidence_id_validation_response.dart';
import '../models/preparation_scan_request.dart';
import '../models/proof_of_delivery_request.dart';
import '../models/receive_unit_at_node_request.dart';
import '../models/reconcile_node_reception_request.dart';
import '../models/route_lifecycle_request.dart';
import '../models/scan_batch_request.dart';
import '../models/scan_batch_response.dart';
import '../models/scan_request.dart';
import '../models/status2.dart';
import '../models/stop_arrived_request.dart';
import '../models/unload_scan_request.dart';
import '../models/verify_label_request.dart';

part 'execution_client.g.dart';

@RestApi()
abstract class ExecutionClient {
  factory ExecutionClient(Dio dio, {String? baseUrl}) = _ExecutionClient;

  /// Record a failed delivery attempt with its typed reason.
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/failed')
  Future<PostAppDeliveriesFailedResponse> recordFailedDelivery({
    @Body() required FailedDeliveryRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Driver drops a store-pickup (or transfer) shipment at its store.
  ///
  /// ENTREGA EN TIENDA del chofer. El camión deja en la tienda un pedido que el cliente retira ahí (o un traspaso): el chofer escanea los productos y saca una foto, sin firma ni documento. Este POST cierra la parada del chofer. El pedido NO queda entregado: queda «listo para retirar» (progress.ready_for_pickup_at = hora de esta entrega, y aparece en ready_for_pickup=true de esa tienda). Si es un pedido de cliente (store_pickup) se le avisa una sola vez que ya puede pasar a recogerlo; un traspaso no avisa. La entrega al cliente la registra después la tienda con la prueba de entrega de mostrador.
  ///
  /// Idempotente: repetirlo no duplica el hecho ni el aviso (si la primera vez no llevaba foto, una repetición la liga).
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/{shipmentId}/store-drop')
  Future<PostAppDeliveriesShipmentIdStoreDropResponse> recordStoreDrop({
    @Path('shipmentId') required String shipmentId,
    @Header('Idempotency-Key') String? idempotencyKey,
    @Body() AppDeliveriesShipmentIdStoreDropRequestBody? body,
  });

  /// Upload an evidence photo (proof of delivery or damage) and get its storage reference.
  ///
  /// [idempotencyKey] - Same key returns the original stored reference (201); the photo is never stored twice.
  ///
  /// [kind] - Tipo de evidencia; elige el disco (pod = prueba de entrega, damage = daños). Por defecto pod.
  /// Name not received and was auto-generated.
  @MultiPart()
  @POST('/app/deliveries/photos')
  Future<PostAppDeliveriesPhotosResponse> uploadDeliveryPhoto({
    @Part(name: 'shipment_id') required String shipmentId,
    @Part(name: 'photo') required File photo,
    @Part(name: 'kind') Enum0? kind = Enum0.pod,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Capture delivery evidence linked to the customer (anti-fraud).
  ///
  /// Captura una evidencia de entrega LIGADA AL CLIENTE (firma, documento, prueba de entrega o daño).
  /// Guarda el archivo, calcula su HASH SHA-256 (integridad: una evidencia no se puede intercambiar por.
  /// otra) y deja el hecho con AUDITORÍA inmutable (quién/cuándo/GPS) más el snapshot de la identidad del.
  /// cliente contra el que se valida. El estado de validación arranca `pending`: lo resuelve un validador.
  /// asíncrono on-premise (nunca bloquea la entrega). Idempotente por `Idempotency-Key`. Devuelve el.
  /// estado completo de las evidencias del envío (la nueva primero).
  ///
  /// [kind] - Name not received and was auto-generated.
  ///
  /// [documentId] - Número de documento del cliente (contra el que se valida la foto del carnet).
  @MultiPart()
  @POST('/app/deliveries/evidence')
  Future<DeliveryEvidenceCollection> captureDeliveryEvidence({
    @Part(name: 'shipment_id') required String shipmentId,
    @Part(name: 'kind') required Enum1 kind,
    @Part(name: 'photo') required File photo,
    @Part(name: 'customer_id') String? customerId,
    @Part(name: 'document_id') String? documentId,
    @Part(name: 'customer_name') String? customerName,
    @Part(name: 'customer_phone') String? customerPhone,
    @Part(name: 'lat') num? lat,
    @Part(name: 'lng') num? lng,
    @Part(name: 'captured_at') DateTime? capturedAt,
  });

  /// List a shipment's evidence with its anti-fraud validation status
  @GET('/app/deliveries/{shipmentId}/evidence')
  Future<DeliveryEvidenceCollection> getDeliveryEvidence({
    @Path('shipmentId') required String shipmentId,
  });

  /// Record proof of delivery and close the delivery as delivered.
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/proof-of-delivery')
  Future<PostAppDeliveriesProofOfDeliveryResponse> recordProofOfDelivery({
    @Body() required ProofOfDeliveryRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Alias of proof-of-delivery for a whole shipment (unit_ids), one confirmation/photo/GPS.
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/{shipmentId}/complete')
  Future<PostAppDeliveriesShipmentIdCompleteResponse> completeDelivery({
    @Path('shipmentId') required String shipmentId,
    @Body() required ProofOfDeliveryRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Report arrival at the stop (geofence or manual); first arrival wins.
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/{shipmentId}/arrived')
  Future<PostAppDeliveriesShipmentIdArrivedResponse> markStopArrived({
    @Path('shipmentId') required String shipmentId,
    @Body() required StopArrivedRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Drain the offline queue in one request (per-item result, 207).
  ///
  /// Each item goes through the same command as its single endpoint. Idempotent per item key (also against keys already applied by the single endpoints). A rejected item can be retried with the same key. 429 responses carry Retry-After.
  @POST('/app/deliveries/scans/batch')
  Future<ScanBatchResponse> recordScanBatch({
    @Body() required ScanBatchRequest body,
  });

  /// Record a validated load scan of a unit onto the vehicle.
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/scans/load')
  Future<PostAppDeliveriesScansLoadResponse> recordLoadScan({
    @Body() required ScanRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Record the reception of a unit at a logistics node.
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/scans/node-reception')
  Future<PostAppDeliveriesScansNodeReceptionResponse> recordNodeReception({
    @Body() required NodeReceptionRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Open a node reception for a shipment at a destination node (all internal corridors).
  ///
  /// Abre la recepción de un envío que llega a un nodo destino por un corredor interno (CD→CD,.
  /// CD→tienda, tienda→tienda, tienda→CD). Anuncia los productos esperados. Idempotente por el par.
  /// envío+nodo destino.
  @POST('/app/node-receptions')
  Future<PostAppNodeReceptionsResponse> openNodeReception({
    @Body() required OpenNodeReceptionRequest body,
  });

  /// List node receptions with their reception status (no N+1).
  ///
  /// [nodeId] - Store users default to (and are limited to) their own node.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/node-receptions')
  Future<GetAppNodeReceptionsResponse> listNodeReceptions({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('node_id') String? nodeId,
    @Query('status') Status2? status,
    @Query('cursor') String? cursor,
  });

  /// Assign the shelf location of a received product (idempotent)
  @POST('/app/node-receptions/{shipmentId}/units/{unitId}/location')
  Future<PostAppNodeReceptionsShipmentIdUnitsUnitIdLocationResponse>
  assignShelfLocation({
    @Path('shipmentId') required String shipmentId,
    @Path('unitId') required String unitId,
    @Body() required AssignShelfLocationRequest body,
  });

  /// Assign one shelf location to many received products (atomic batch, unit_ids required)
  @POST('/app/node-receptions/{shipmentId}/units/location')
  Future<PostAppNodeReceptionsShipmentIdUnitsLocationResponse>
  assignShelfLocationBatch({
    @Path('shipmentId') required String shipmentId,
    @Body() required AssignShelfLocationRequest body,
  });

  /// Current state of a shipment reception at a node (expected, received, discrepancies).
  ///
  /// [shipmentId] - Shipment UUID.
  ///
  /// [nodeId] - Destination node UUID.
  @GET('/app/node-receptions/{shipmentId}/{nodeId}')
  Future<GetAppNodeReceptionsShipmentIdNodeIdResponse> getNodeReception({
    @Path('shipmentId') required String shipmentId,
    @Path('nodeId') required String nodeId,
  });

  /// Record the scan of a unit received at a node (immutable, idempotent).
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/node-receptions/units')
  Future<PostAppNodeReceptionsUnitsResponse> receiveUnitAtNode({
    @Body() required ReceiveUnitAtNodeRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Reconcile a node reception (compare received against expected, record missing/surplus).
  ///
  /// Cierra la recepción conciliando lo recibido contra lo esperado y graba las discrepancias.
  /// (faltantes/sobrantes). El evento de conciliación alimenta tracking y el conector SAP por el.
  /// outbox. Idempotente: reconciliar dos veces no re-emite el evento.
  @POST('/app/node-receptions/reconcile')
  Future<PostAppNodeReceptionsReconcileResponse> reconcileNodeReception({
    @Body() required ReconcileNodeReceptionRequest body,
  });

  /// Record a preparation scan (EAN to label to lane) of a unit.
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/scans/preparation')
  Future<PostAppDeliveriesScansPreparationResponse> recordPreparationScan({
    @Body() required PreparationScanRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Record a guided unload of a unit at a stop (what comes off at each point).
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/scans/unload')
  Future<PostAppDeliveriesScansUnloadResponse> recordUnloadScan({
    @Body() required UnloadScanRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Report an issue during an in-progress delivery (does not close it).
  ///
  /// The driver reports an obstacle during a delivery that is still IN PROGRESS. It is distinct from.
  /// a failed delivery (which closes the delivery) and from a vehicle incident (breakdown/accident).
  /// The delivery is NOT closed: the platform records the issue as an immutable fact and notifies the.
  /// control tower / customer through the outbox. Idempotent by `Idempotency-Key`.
  ///
  /// [shipmentId] - Shipment UUID.
  ///
  /// [idempotencyKey] - Offline-first idempotency key; resending the same report does not duplicate the fact.
  @POST('/app/deliveries/{shipmentId}/issues')
  Future<PostAppDeliveriesShipmentIdIssuesResponse> reportDeliveryIssue({
    @Path('shipmentId') required String shipmentId,
    @Body() required DeliveryIssueRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Current state of a shipment delivery with its scans.
  ///
  /// [shipmentId] - Shipment UUID.
  @GET('/app/deliveries/{shipmentId}')
  Future<GetAppDeliveriesShipmentIdResponse> getDeliveryState({
    @Path('shipmentId') required String shipmentId,
  });

  /// Server-side counter-check of a scanned QR label signature (offline verification).
  ///
  /// The Flutter app verifies the signed label offline with the public key bundle; this endpoint repeats the check on the server for dubious cases. A forged or edited label is a business result (200 with valid=false), not a system error.
  @POST('/app/labels/verify')
  Future<PostAppLabelsVerifyResponse> verifyLabel({
    @Body() required VerifyLabelRequest body,
  });

  /// Assign every shipment of an order to a truck (attaches it to the route of the day).
  ///
  /// Adjunta cada envío del pedido a la ruta del vehículo (crea la parada si falta). El vehículo debe estar operativo (available / in_service) y APTO (sin ítem crítico fallado en el pre-viaje sin habilitar).
  @POST('/app/orders/{orderNumber}/vehicle')
  Future<PostAppOrdersOrderNumberVehicleResponse> assignOrderVehicle({
    @Path('orderNumber') required String orderNumber,
    @Body() required AppOrdersOrderNumberVehicleRequestBody body,
  });

  /// Driver route sheet — deliveries assigned to a vehicle.
  ///
  /// [vehicleId] - Vehicle UUID.
  ///
  /// [status] - Lista separada por comas de estados de entrega a incluir (pending, prepared, loaded, in_transit, delivered, failed), sin distinguir mayúsculas. Un valor desconocido se ignora.
  ///
  /// [open] - true = atajo de la pantalla de carga: excluye las entregas ya entregadas y las fallidas. Se ignora si viene `status`.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/vehicles/{vehicleId}/deliveries')
  Future<GetAppVehiclesVehicleIdDeliveriesResponse> listVehicleDeliveries({
    @Path('vehicleId') required String vehicleId,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('status') String? status,
    @Query('open') bool? open,
    @Query('cursor') String? cursor,
  });

  /// Open the driver route of the day (idempotent; first call wins).
  ///
  /// [vehicleId] - Vehicle UUID.
  @POST('/app/vehicles/{vehicleId}/route/start')
  Future<PostAppVehiclesVehicleIdRouteStartResponse> startDriverRoute({
    @Path('vehicleId') required String vehicleId,
    @Body() required RouteLifecycleRequest body,
  });

  /// Close the driver route of the day (idempotent; pending stops stay as they are).
  ///
  /// [vehicleId] - Vehicle UUID.
  @POST('/app/vehicles/{vehicleId}/route/close')
  Future<PostAppVehiclesVehicleIdRouteCloseResponse> closeDriverRoute({
    @Path('vehicleId') required String vehicleId,
    @Body() required RouteLifecycleRequest body,
  });

  /// Report a vehicle incident (breakdown or accident) from the driver app.
  ///
  /// The driver reports a breakdown or accident with their vehicle while on route. The platform.
  /// reacts automatically: it records the incident as an immutable fact and reschedules ONLY the.
  /// still-pending stops of the route — delivered or failed stops are never touched.
  ///
  /// - MAJOR (serious accident/breakdown): the vehicle is taken OUT OF SERVICE (fleet) and the.
  ///   pending shipments are rescheduled to the NEXT DAY (planning backlog). The route is suspended.
  /// - MINOR: the pending stops' ETAs are pushed by the configured delay and the route continues.
  ///
  /// Affected customers are notified ("rescheduled" / "en route with delay") and the supervisor is.
  /// alerted, all through the notifications outbox flow. Idempotent by `Idempotency-Key`.
  ///
  /// [vehicleId] - Vehicle UUID.
  ///
  /// [idempotencyKey] - Offline-first idempotency key; resending the same report does not duplicate the fact.
  @POST('/app/vehicles/{vehicleId}/incidents')
  Future<PostAppVehiclesVehicleIdIncidentsResponse> reportVehicleIncident({
    @Path('vehicleId') required String vehicleId,
    @Body() required AppVehiclesVehicleIdIncidentsRequestBody body,
    @Header('Idempotency-Key') String? idempotencyKey,
  });

  /// Record the anti-fraud validation result of a delivery evidence.
  ///
  /// Lo llama el validador anti-fraude ASÍNCRONO (worker/sidecar on-premise) tras procesar la firma o el.
  /// documento. Registra el estado (`ok` | `review` | `mismatch`) — es una SEÑAL, nunca bloquea la.
  /// entrega; `review`/`mismatch` escalan a revisión humana. Dos modos: `status` explícito, o.
  /// `ocr_document_number` para que el backend cruce el número leído contra el documento del cliente.
  @POST('/integrations/evidence/{evidenceId}/validation')
  Future<PostIntegrationsEvidenceEvidenceIdValidationResponse>
  recordEvidenceValidation({
    @Path('evidenceId') required String evidenceId,
    @Body() IntegrationsEvidenceEvidenceIdValidationRequestBody? body,
  });

  /// Driver route — the ordered stops of a vehicle for the day (my route).
  ///
  /// Returns the driver route sheet: the ordered sequence of stops with what to drop at each one, the current stop (next pending) and how many stops remain. With ?date it returns that day's route; without it, the vehicle's open route in progress.
  ///
  /// [vehicleId] - Vehicle UUID.
  ///
  /// [date] - Route day (Y-m-d); omit for the vehicle's open route.
  @GET('/app/vehicles/{vehicleId}/route')
  Future<GetAppVehiclesVehicleIdRouteResponse> getDriverRoute({
    @Path('vehicleId') required String vehicleId,
    @Query('date') DateTime? date,
  });

  /// Assemble the driver route of the day from the published plan stops.
  ///
  /// Assembles the driver route of the day. The backend builds the ordered stops FROM THE PUBLISHED PLAN (planning); the client only chooses the date. Send the body WITHOUT `stops` (or with an empty array) to assemble from the plan. `stops` is optional and only needed to override with an explicit list. If there is no published plan for the vehicle on that date, responds 422.
  ///
  /// [vehicleId] - Vehicle UUID.
  @POST('/app/vehicles/{vehicleId}/route')
  Future<PostAppVehiclesVehicleIdRouteResponse> assembleDailyRoute({
    @Path('vehicleId') required String vehicleId,
    @Body() required AppVehiclesVehicleIdRouteRequestBody body,
  });
}
