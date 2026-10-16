// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/alert_type.dart';
import '../models/app_telemetry_geofences_geofence_id_redraw_request_body.dart';
import '../models/app_telemetry_geofences_geofence_id_rename_request_body.dart';
import '../models/app_telemetry_geofences_request_body.dart';
import '../models/app_telemetry_pings_request_body.dart';
import '../models/geofence_type.dart';
import '../models/get_app_telemetry_alerts_response.dart';
import '../models/get_app_telemetry_fleet_live_response.dart';
import '../models/get_app_telemetry_geofences_response.dart';
import '../models/get_app_telemetry_streets_response.dart';
import '../models/get_app_telemetry_trips_response.dart';
import '../models/get_app_telemetry_vehicles_vehicle_id_summary_response.dart';
import '../models/get_app_telemetry_vehicles_vehicle_id_track_response.dart';
import '../models/integrations_telemetry_pings_request_body.dart';

part 'telemetry_client.g.dart';

@RestApi()
abstract class TelemetryClient {
  factory TelemetryClient(Dio dio, {String? baseUrl}) = _TelemetryClient;

  /// Ingest a batch of vehicle GPS pings from the internal app.
  ///
  /// El app agrupa lecturas GPS para ahorrar batería/datos y las envía en lote. El origen queda fijado como 'app' por la puerta. La respuesta es un acuse 202 (el procesamiento es asíncrono vía outbox).
  @POST('/app/telemetry/pings')
  Future<AcceptedEnvelope> recordAppVehiclePings({
    @Body() required AppTelemetryPingsRequestBody body,
  });

  /// Live positions of the whole fleet
  @GET('/app/telemetry/fleet/live')
  Future<GetAppTelemetryFleetLiveResponse> getLiveFleetPositions();

  /// Track (path) of a vehicle between two instants.
  ///
  /// Devuelve la traza del vehículo entre `from` y `to` (fechas ISO 8601). Si faltan, se asume la última ventana de 24 horas.
  @GET('/app/telemetry/vehicles/{vehicleId}/track')
  Future<GetAppTelemetryVehiclesVehicleIdTrackResponse> getVehicleTrack({
    @Path('vehicleId') required String vehicleId,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
  });

  /// Daily telemetry summary of a vehicle.
  ///
  /// [date] - Day to summarize (YYYY-MM-DD). Defaults to today.
  @GET('/app/telemetry/vehicles/{vehicleId}/summary')
  Future<GetAppTelemetryVehiclesVehicleIdSummaryResponse>
  getVehicleTelemetrySummary({
    @Path('vehicleId') required String vehicleId,
    @Query('date') DateTime? date,
  });

  /// List trips.
  ///
  /// [date] - Day filter (YYYY-MM-DD).
  @GET('/app/telemetry/trips')
  Future<GetAppTelemetryTripsResponse> listTelemetryTrips({
    @Query('vehicle_id') String? vehicleId,
    @Query('date') DateTime? date,
  });

  /// List misuse alerts
  @GET('/app/telemetry/alerts')
  Future<GetAppTelemetryAlertsResponse> listTelemetryAlerts({
    @Query('vehicle_id') String? vehicleId,
    @Query('type') AlertType? type,
    @Query('acknowledged') bool? acknowledged,
  });

  /// Acknowledge an alert
  @POST('/app/telemetry/alerts/{alertId}/acknowledge')
  Future<AcceptedEnvelope> acknowledgeTelemetryAlert({
    @Path('alertId') required String alertId,
  });

  /// List geofences
  @GET('/app/telemetry/geofences')
  Future<GetAppTelemetryGeofencesResponse> listGeofences({
    @Query('type') GeofenceType? type,
  });

  /// Define a geofence
  @POST('/app/telemetry/geofences')
  Future<AcceptedEnvelope> defineGeofence({
    @Body() required AppTelemetryGeofencesRequestBody body,
  });

  /// Rename a geofence.
  ///
  /// [geofenceId] - UUID v7 de la geocerca.
  @POST('/app/telemetry/geofences/{geofenceId}/rename')
  Future<AcceptedEnvelope> renameGeofence({
    @Path('geofenceId') required String geofenceId,
    @Body() required AppTelemetryGeofencesGeofenceIdRenameRequestBody body,
  });

  /// Redraw a geofence polygon.
  ///
  /// [geofenceId] - UUID v7 de la geocerca.
  @POST('/app/telemetry/geofences/{geofenceId}/redraw')
  Future<AcceptedEnvelope> redrawGeofence({
    @Path('geofenceId') required String geofenceId,
    @Body() required AppTelemetryGeofencesGeofenceIdRedrawRequestBody body,
  });

  /// Activate a geofence.
  ///
  /// [geofenceId] - UUID v7 de la geocerca.
  @POST('/app/telemetry/geofences/{geofenceId}/activate')
  Future<AcceptedEnvelope> activateGeofence({
    @Path('geofenceId') required String geofenceId,
  });

  /// Deactivate a geofence.
  ///
  /// [geofenceId] - UUID v7 de la geocerca.
  @POST('/app/telemetry/geofences/{geofenceId}/deactivate')
  Future<AcceptedEnvelope> deactivateGeofence({
    @Path('geofenceId') required String geofenceId,
  });

  /// Delete a geofence.
  ///
  /// [geofenceId] - UUID v7 de la geocerca.
  @DELETE('/app/telemetry/geofences/{geofenceId}')
  Future<AcceptedEnvelope> deleteGeofence({
    @Path('geofenceId') required String geofenceId,
  });

  /// Aggregated street traffic for the congestion map.
  ///
  /// [bbox] - Bounding box as `min_lat,min_lng,max_lat,max_lng` to limit the result to the visible map area.
  @GET('/app/telemetry/streets')
  Future<GetAppTelemetryStreetsResponse> getStreetTraffic({
    @Query('bbox') String? bbox,
  });

  /// Ingest a batch of vehicle GPS pings from an external provider.
  ///
  /// Ingesta de lecturas GPS de proveedores externos (dispositivos de terceros). El origen queda fijado como 'integration' por la puerta. La respuesta es un acuse 202.
  @POST('/integrations/telemetry/pings')
  Future<AcceptedEnvelope> recordIntegrationVehiclePings({
    @Body() required IntegrationsTelemetryPingsRequestBody body,
  });
}
