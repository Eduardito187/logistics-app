// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_vehicles_vehicle_id_incidents_request_body.dart';
import '../models/app_vehicles_vehicle_id_route_request_body.dart';
import '../models/enum0.dart';
import '../models/failed_delivery_request.dart';
import '../models/get_app_deliveries_shipment_id_response.dart';
import '../models/get_app_node_receptions_shipment_id_node_id_response.dart';
import '../models/get_app_vehicles_vehicle_id_deliveries_response.dart';
import '../models/get_app_vehicles_vehicle_id_route_response.dart';
import '../models/node_reception_request.dart';
import '../models/open_node_reception_request.dart';
import '../models/post_app_deliveries_failed_response.dart';
import '../models/post_app_deliveries_photos_response.dart';
import '../models/post_app_deliveries_proof_of_delivery_response.dart';
import '../models/post_app_deliveries_scans_load_response.dart';
import '../models/post_app_deliveries_scans_node_reception_response.dart';
import '../models/post_app_deliveries_scans_preparation_response.dart';
import '../models/post_app_deliveries_scans_unload_response.dart';
import '../models/post_app_labels_verify_response.dart';
import '../models/post_app_node_receptions_reconcile_response.dart';
import '../models/post_app_node_receptions_response.dart';
import '../models/post_app_node_receptions_units_response.dart';
import '../models/post_app_vehicles_vehicle_id_incidents_response.dart';
import '../models/post_app_vehicles_vehicle_id_route_response.dart';
import '../models/preparation_scan_request.dart';
import '../models/proof_of_delivery_request.dart';
import '../models/receive_unit_at_node_request.dart';
import '../models/reconcile_node_reception_request.dart';
import '../models/scan_request.dart';
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

  /// Upload an evidence photo (proof of delivery or damage) and get its storage reference.
  ///
  /// [kind] - Tipo de evidencia; elige el disco (pod = prueba de entrega, damage = daños). Por defecto pod.
  /// Name not received and was auto-generated.
  @MultiPart()
  @POST('/app/deliveries/photos')
  Future<PostAppDeliveriesPhotosResponse> uploadDeliveryPhoto({
    @Part(name: 'shipment_id') required String shipmentId,
    @Part(name: 'photo') required File photo,
    @Part(name: 'kind') Enum0? kind = Enum0.pod,
  });

  /// Record proof of delivery and close the delivery as delivered.
  ///
  /// [idempotencyKey] - Offline idempotency key for the scan; a resend with the same key does not duplicate the fact. REQUIRED for every write scan: send it here or in the body field idempotency_key. A write with neither is rejected with 422.
  @POST('/app/deliveries/proof-of-delivery')
  Future<PostAppDeliveriesProofOfDeliveryResponse> recordProofOfDelivery({
    @Body() required ProofOfDeliveryRequest body,
    @Header('Idempotency-Key') String? idempotencyKey,
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
  /// CD→tienda, tienda→tienda, tienda→CD). Anuncia los bultos esperados. Idempotente por el par.
  /// envío+nodo destino.
  @POST('/app/node-receptions')
  Future<PostAppNodeReceptionsResponse> openNodeReception({
    @Body() required OpenNodeReceptionRequest body,
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

  /// Driver route sheet — deliveries assigned to a vehicle.
  ///
  /// [vehicleId] - Vehicle UUID.
  @GET('/app/vehicles/{vehicleId}/deliveries')
  Future<GetAppVehiclesVehicleIdDeliveriesResponse> listVehicleDeliveries({
    @Path('vehicleId') required String vehicleId,
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
  /// [vehicleId] - Vehicle UUID.
  @POST('/app/vehicles/{vehicleId}/route')
  Future<PostAppVehiclesVehicleIdRouteResponse> assembleDailyRoute({
    @Path('vehicleId') required String vehicleId,
    @Body() required AppVehiclesVehicleIdRouteRequestBody body,
  });
}
