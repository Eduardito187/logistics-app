// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_fleet_helpers_helper_id_availability_request_body.dart';
import '../models/app_fleet_vehicles_vehicle_id_status_request_body.dart';
import '../models/assemble_crew_request.dart';
import '../models/conduct_pre_trip_checklist_request.dart';
import '../models/document_owner_type.dart';
import '../models/get_app_fleet_documents_response.dart';
import '../models/get_app_fleet_drivers_response.dart';
import '../models/get_app_fleet_expiring_documents_response.dart';
import '../models/get_app_fleet_helpers_response.dart';
import '../models/get_app_fleet_my_crew_response.dart';
import '../models/get_app_fleet_pre_trip_checklists_response.dart';
import '../models/get_app_fleet_vehicles_response.dart';
import '../models/patch_app_fleet_helpers_helper_id_availability_response.dart';
import '../models/patch_app_fleet_vehicles_vehicle_id_status_response.dart';
import '../models/post_app_fleet_crews_response.dart';
import '../models/post_app_fleet_pre_trip_checklists_response.dart';
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

  /// List fleet drivers
  @GET('/app/fleet/drivers')
  Future<GetAppFleetDriversResponse> fleetListDrivers({
    @Query('only_active') bool? onlyActive,
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
  /// [date] - Assembly date to query (Y-m-d). Defaults to today in America/La_Paz.
  @GET('/app/fleet/my-crew')
  Future<GetAppFleetMyCrewResponse> fleetGetMyCrew({
    @Query('date') DateTime? date,
  });

  /// List pre-trip checklists (inspections)
  @GET('/app/fleet/pre-trip-checklists')
  Future<GetAppFleetPreTripChecklistsResponse> fleetListPreTripChecklists({
    @Query('vehicle_id') String? vehicleId,
    @Query('only_passed') bool? onlyPassed,
  });

  /// Record a conducted pre-trip checklist
  @POST('/app/fleet/pre-trip-checklists')
  Future<PostAppFleetPreTripChecklistsResponse> fleetConductPreTripChecklist({
    @Body() required ConductPreTripChecklistRequest body,
  });

  /// List fleet vehicles
  @GET('/app/fleet/vehicles')
  Future<GetAppFleetVehiclesResponse> fleetListVehicles({
    @Query('status') VehicleStatus? status,
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
