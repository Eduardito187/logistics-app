// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_app_tracking_shipments_shipment_id_response.dart';
import '../models/get_app_tracking_shipments_shipment_id_units_response.dart';
import '../models/get_channels_tracking_token_response.dart';
import '../models/get_channels_tracking_token_units_response.dart';
import '../models/post_app_tracking_shipments_shipment_id_position_response.dart';
import '../models/post_integrations_tracking_shipments_shipment_id_position_response.dart';
import '../models/truck_position_input.dart';

part 'tracking_client.g.dart';

@RestApi()
abstract class TrackingClient {
  factory TrackingClient(Dio dio, {String? baseUrl}) = _TrackingClient;

  /// Internal shipment tracking by shipment id.
  ///
  /// Puerta app (personal interno). Devuelve el seguimiento completo, incluidas las claves internas (id de seguimiento, id de envío y token).
  ///
  /// [shipmentId] - UUID del envío.
  @GET('/app/tracking/shipments/{shipmentId}')
  Future<GetAppTrackingShipmentsShipmentIdResponse> getShipmentTracking({
    @Path('shipmentId') required String shipmentId,
  });

  /// Internal per-parcel tracking detail by shipment id.
  ///
  /// Puerta app (personal interno). Devuelve el detalle per-bulto del seguimiento del envío: estado, última ubicación (nodo) y último escaneo de cada bulto. Alimenta la reconciliación de bultos.
  ///
  /// [shipmentId] - UUID del envío.
  @GET('/app/tracking/shipments/{shipmentId}/units')
  Future<GetAppTrackingShipmentsShipmentIdUnitsResponse> getShipmentUnits({
    @Path('shipmentId') required String shipmentId,
  });

  /// Ingest live GPS position from the driver app.
  ///
  /// Puerta app (flujo del chofer). Escritura de alta frecuencia (~3 req/s). El mismo caso de uso se expone en la puerta integrations para telemetría externa normalizada.
  ///
  /// [shipmentId] - UUID del envío.
  @POST('/app/tracking/shipments/{shipmentId}/position')
  Future<PostAppTrackingShipmentsShipmentIdPositionResponse>
  ingestTruckPositionFromApp({
    @Path('shipmentId') required String shipmentId,
    @Body() required TruckPositionInput body,
  });

  /// Public tracking page by opaque token (no PII).
  ///
  /// Puerta channels. Devuelve el estado visible del envío, cuántas paradas faltan antes de la del cliente (remaining_stops), su posición en la ruta (route_position), un mensaje legible en español ("Tu pedido está a N paradas"), la ETA y la última posición del camión. No expone datos personales ni claves internas.
  ///
  /// [token] - Token opaco del enlace de rastreo.
  @GET('/channels/tracking/{token}')
  Future<GetChannelsTrackingTokenResponse> getPublicTracking({
    @Path('token') required String token,
  });

  /// Public per-parcel breakdown by opaque token (no PII).
  ///
  /// Puerta channels. Devuelve el desglose de bultos del envío (etiqueta humana, estado y un mensaje en español por bulto), sin datos personales ni claves internas. Mismo token que la página pública del envío.
  ///
  /// [token] - Token opaco del enlace de rastreo.
  @GET('/channels/tracking/{token}/units')
  Future<GetChannelsTrackingTokenUnitsResponse> getPublicUnits({
    @Path('token') required String token,
  });

  /// Ingest live GPS position from external telemetry.
  ///
  /// Puerta integrations (credenciales de servicio). Telemetría externa ya normalizada; mismo caso de uso que la ingesta de la app.
  ///
  /// [shipmentId] - UUID del envío.
  @POST('/integrations/tracking/shipments/{shipmentId}/position')
  Future<PostIntegrationsTrackingShipmentsShipmentIdPositionResponse>
  ingestTruckPositionFromIntegration({
    @Path('shipmentId') required String shipmentId,
    @Body() required TruckPositionInput body,
  });
}
