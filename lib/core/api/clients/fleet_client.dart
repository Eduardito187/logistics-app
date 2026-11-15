// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/app_fleet_helpers_helper_id_availability_request_body.dart';
import '../models/app_fleet_vehicles_vehicle_id_send_to_maintenance_request_body.dart';
import '../models/app_fleet_vehicles_vehicle_id_status_request_body.dart';
import '../models/assemble_crew_request.dart';
import '../models/clear_vehicle_fitness_request.dart';
import '../models/conduct_pre_trip_checklist_request.dart';
import '../models/document_owner_type.dart';
import '../models/get_app_fleet_checklist_template_response.dart';
import '../models/get_app_fleet_crews_response.dart';
import '../models/get_app_fleet_documents_response.dart';
import '../models/get_app_fleet_drivers_response.dart';
import '../models/get_app_fleet_expiring_documents_response.dart';
import '../models/get_app_fleet_helpers_response.dart';
import '../models/get_app_fleet_my_crew_response.dart';
import '../models/get_app_fleet_pre_trip_checklists_latest_response.dart';
import '../models/get_app_fleet_pre_trip_checklists_response.dart';
import '../models/get_app_fleet_vehicles_response.dart';
import '../models/get_app_fleet_vehicles_vehicle_id_fitness_response.dart';
import '../models/patch_app_fleet_helpers_helper_id_availability_response.dart';
import '../models/patch_app_fleet_vehicles_vehicle_id_status_response.dart';
import '../models/post_app_fleet_crews_response.dart';
import '../models/post_app_fleet_pre_trip_checklists_response.dart';
import '../models/post_app_fleet_vehicles_vehicle_id_clear_fitness_response.dart';
import '../models/post_app_fleet_vehicles_vehicle_id_send_to_maintenance_response.dart';
import '../models/post_integrations_fleet_documents_response.dart';
import '../models/post_integrations_fleet_drivers_response.dart';
import '../models/post_integrations_fleet_helpers_response.dart';
import '../models/post_integrations_fleet_vehicles_response.dart';
import '../models/register_document_request.dart';
import '../models/register_driver_request.dart';
import '../models/register_helper_request.dart';
import '../models/register_vehicle_request.dart';
import '../models/vehicle_status.dart';

part 'fleet_client.g.dart';

@RestApi()
abstract class FleetClient {
  factory FleetClient(Dio dio, {String? baseUrl}) = _FleetClient;

  /// List crews (which driver has which vehicle) by date, vehicle or driver.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/fleet/crews')
  Future<GetAppFleetCrewsResponse> fleetListCrews({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('date') DateTime? date,
    @Query('vehicle_id') String? vehicleId,
    @Query('driver_id') String? driverId,
    @Query('cursor') String? cursor,
  });

  /// Assemble a crew for a given date
  @POST('/app/fleet/crews')
  Future<PostAppFleetCrewsResponse> fleetAssembleCrew({
    @Body() required AssembleCrewRequest body,
  });

  /// List fleet documents (with expiry and S3 file)
  @GET('/app/fleet/documents')
  Future<GetAppFleetDocumentsResponse> fleetListDocuments({
    @Query('owner_type') DocumentOwnerType? ownerType,
  });

  /// Change a crew (replaces it atomically; the previous one is kept if the new one is rejected)
  @PUT('/app/fleet/crews/{crewId}')
  Future<AcceptedEnvelope> fleetUpdateCrew({
    @Path('crewId') required String crewId,
    @Body() required AssembleCrewRequest body,
  });

  /// Remove a crew assignment
  @DELETE('/app/fleet/crews/{crewId}')
  Future<AcceptedEnvelope> fleetDeleteCrew({
    @Path('crewId') required String crewId,
  });

  /// List fleet drivers.
  ///
  /// [q] - Búsqueda por nombre, licencia, documento o teléfono (contiene, sin distinguir mayúsculas).
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/fleet/drivers')
  Future<GetAppFleetDriversResponse> fleetListDrivers({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('only_active') bool? onlyActive,
    @Query('q') String? q,
    @Query('cursor') String? cursor,
  });

  /// List vehicle and driver documents expiring within N days (expired included)
  @GET('/app/fleet/expiring-documents')
  Future<GetAppFleetExpiringDocumentsResponse> fleetListExpiringDocuments({
    @Query('days') required int days,
    @Query('reference_date') DateTime? referenceDate,
  });

  /// List fleet helpers
  @GET('/app/fleet/helpers')
  Future<GetAppFleetHelpersResponse> fleetListHelpers({
    @Query('only_active') bool? onlyActive,
  });

  /// Activate or deactivate a helper
  @PATCH('/app/fleet/helpers/{helperId}/availability')
  Future<PatchAppFleetHelpersHelperIdAvailabilityResponse>
  fleetSetHelperAvailability({
    @Path('helperId') required String helperId,
    @Body() required AppFleetHelpersHelperIdAvailabilityRequestBody body,
  });

  /// Get the authenticated driver's crew assignment for a date.
  ///
  /// Returns the vehicle (truck) and crew (driver + helpers) the admin assembled for the AUTHENTICATED driver on a date. The driver does not pick the vehicle; it is assigned. The account→driver link is `users.driver_id` (a by-value reference to fleet_drivers.id). Responds 404 (RFC 7807) when the authenticated account is not linked to a driver, or has no crew assembled for the date.
  ///
  /// [date] - Assembly date (YYYY-MM-DD). Defaults to today in America/La_Paz. A full ISO 8601 date-time is tolerated and normalized to the calendar date as written by the client.
  @GET('/app/fleet/my-crew')
  Future<GetAppFleetMyCrewResponse> fleetGetMyCrew({
    @Query('date') DateTime? date,
  });

  /// List pre-trip checklists (inspections).
  ///
  /// [routeId] - Filter checklists by route/trip to tell whether a route already has its checklist.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/fleet/pre-trip-checklists')
  Future<GetAppFleetPreTripChecklistsResponse> fleetListPreTripChecklists({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('vehicle_id') String? vehicleId,
    @Query('only_passed') bool? onlyPassed,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
    @Query('route_id') String? routeId,
    @Query('cursor') String? cursor,
  });

  /// Record a conducted pre-trip checklist
  @POST('/app/fleet/pre-trip-checklists')
  Future<PostAppFleetPreTripChecklistsResponse> fleetConductPreTripChecklist({
    @Body() required ConductPreTripChecklistRequest body,
  });

  /// Latest pre-trip checklist of a vehicle
  @GET('/app/fleet/pre-trip-checklists/latest')
  Future<GetAppFleetPreTripChecklistsLatestResponse>
  fleetGetLatestPreTripChecklist({
    @Query('vehicle_id') required String vehicleId,
  });

  /// Get the active pre-trip checklist template.
  ///
  /// [vehicleType] - Specific template for this vehicle type; falls back to the default template.
  ///
  /// [vehicleId] - Adds vehicle_fitness (today, America/La_Paz).
  @GET('/app/fleet/checklist-template')
  Future<GetAppFleetChecklistTemplateResponse> fleetGetChecklistTemplate({
    @Query('vehicle_type') String? vehicleType,
    @Query('vehicle_id') String? vehicleId,
  });

  /// Vehicle fitness to dispatch on a date.
  ///
  /// [date] - Defaults to today (America/La_Paz). A full ISO 8601 date-time is also accepted.
  @GET('/app/fleet/vehicles/{vehicleId}/fitness')
  Future<GetAppFleetVehiclesVehicleIdFitnessResponse> fleetGetVehicleFitness({
    @Path('vehicleId') required String vehicleId,
    @Query('date') DateTime? date,
  });

  /// Clear an unfit vehicle for dispatch after repair (supervisor/admin)
  @POST('/app/fleet/vehicles/{vehicleId}/clear-fitness')
  Future<PostAppFleetVehiclesVehicleIdClearFitnessResponse>
  fleetClearVehicleFitness({
    @Path('vehicleId') required String vehicleId,
    @Body() required ClearVehicleFitnessRequest body,
  });

  /// List fleet vehicles.
  ///
  /// [q] - Búsqueda por placa (contiene, sin distinguir mayúsculas).
  ///
  /// [nodeId] - Solo vehículos cuya sede (home_base_node_id) es ese nodo.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/fleet/vehicles')
  Future<GetAppFleetVehiclesResponse> fleetListVehicles({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('status') VehicleStatus? status,
    @Query('q') String? q,
    @Query('node_id') String? nodeId,
    @Query('cursor') String? cursor,
  });

  /// Send a vehicle to maintenance now (opens the maintenance order and sets status in one call).
  ///
  /// Solo supervisor o admin. Abre la orden de mantenimiento, deja el vehículo en `maintenance` y resuelve su ruta: las paradas PENDIENTES pasan al camión de `reassign_to_vehicle_id` (con su entrega) o, si no se indica, se liberan de la ruta y quedan por asignar. Las paradas ya atendidas no se tocan. Se aplica completo o nada (422 si el camión destino no está apto).
  @POST('/app/fleet/vehicles/{vehicleId}/send-to-maintenance')
  Future<PostAppFleetVehiclesVehicleIdSendToMaintenanceResponse>
  fleetSendVehicleToMaintenance({
    @Path('vehicleId') required String vehicleId,
    @Body() AppFleetVehiclesVehicleIdSendToMaintenanceRequestBody? body,
  });

  /// Change a vehicle operational status (enable / disable / maintenance)
  @PATCH('/app/fleet/vehicles/{vehicleId}/status')
  Future<PatchAppFleetVehiclesVehicleIdStatusResponse>
  fleetChangeVehicleStatus({
    @Path('vehicleId') required String vehicleId,
    @Body() required AppFleetVehiclesVehicleIdStatusRequestBody body,
  });

  /// Register a fleet document (master data sync)
  @POST('/integrations/fleet/documents')
  Future<PostIntegrationsFleetDocumentsResponse> fleetRegisterDocument({
    @Body() required RegisterDocumentRequest body,
  });

  /// Register a driver (master data sync)
  @POST('/integrations/fleet/drivers')
  Future<PostIntegrationsFleetDriversResponse> fleetRegisterDriver({
    @Body() required RegisterDriverRequest body,
  });

  /// Register a helper (master data sync)
  @POST('/integrations/fleet/helpers')
  Future<PostIntegrationsFleetHelpersResponse> fleetRegisterHelper({
    @Body() required RegisterHelperRequest body,
  });

  /// Register a vehicle (master data sync)
  @POST('/integrations/fleet/vehicles')
  Future<PostIntegrationsFleetVehiclesResponse> fleetRegisterVehicle({
    @Body() required RegisterVehicleRequest body,
  });
}
