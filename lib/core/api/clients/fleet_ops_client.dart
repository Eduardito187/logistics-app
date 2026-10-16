// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/close_departure_request.dart';
import '../models/complete_maintenance_request.dart';
import '../models/define_maintenance_plan_request.dart';
import '../models/define_vehicle_profile_request.dart';
import '../models/departure_status.dart';
import '../models/expense_category.dart';
import '../models/fuel_type.dart';
import '../models/get_app_fleetops_cost_summary_response.dart';
import '../models/get_app_fleetops_departures_departure_id_response.dart';
import '../models/get_app_fleetops_departures_response.dart';
import '../models/get_app_fleetops_expenses_response.dart';
import '../models/get_app_fleetops_expenses_total_response.dart';
import '../models/get_app_fleetops_fuel_consumption_response.dart';
import '../models/get_app_fleetops_fuel_daily_spend_response.dart';
import '../models/get_app_fleetops_fuel_prices_current_response.dart';
import '../models/get_app_fleetops_fuel_prices_response.dart';
import '../models/get_app_fleetops_maintenance_cost_response.dart';
import '../models/get_app_fleetops_maintenance_due_response.dart';
import '../models/get_app_fleetops_maintenance_orders_order_id_response.dart';
import '../models/get_app_fleetops_maintenance_orders_response.dart';
import '../models/get_app_fleetops_maintenance_plans_response.dart';
import '../models/get_app_fleetops_odometer_response.dart';
import '../models/get_app_fleetops_refuels_response.dart';
import '../models/get_app_fleetops_utilization_response.dart';
import '../models/get_app_fleetops_vehicle_profiles_response.dart';
import '../models/get_app_fleetops_vehicle_profiles_vehicle_id_response.dart';
import '../models/maintenance_status.dart';
import '../models/record_expense_request.dart';
import '../models/record_odometer_request.dart';
import '../models/record_refuel_request.dart';
import '../models/record_service_done_request.dart';
import '../models/register_departure_request.dart';
import '../models/schedule_maintenance_request.dart';
import '../models/set_fuel_price_request.dart';
import '../models/update_vehicle_odometer_request.dart';

part 'fleet_ops_client.g.dart';

@RestApi()
abstract class FleetOpsClient {
  factory FleetOpsClient(Dio dio, {String? baseUrl}) = _FleetOpsClient;

  /// List fuel prices
  @GET('/app/fleetops/fuel-prices')
  Future<GetAppFleetopsFuelPricesResponse> listFleetFuelPrices({
    @Query('fuel_type') FuelType? fuelType,
  });

  /// Set a fuel price effective from a date
  @POST('/app/fleetops/fuel-prices')
  Future<AcceptedEnvelope> setFleetFuelPrice({
    @Body() required SetFuelPriceRequest body,
  });

  /// Get the current fuel price for a fuel type
  @GET('/app/fleetops/fuel-prices/current')
  Future<GetAppFleetopsFuelPricesCurrentResponse> getCurrentFleetFuelPrice({
    @Query('fuel_type') required FuelType fuelType,
  });

  /// List refuels
  @GET('/app/fleetops/refuels')
  Future<GetAppFleetopsRefuelsResponse> listFleetRefuels({
    @Query('vehicle_id') String? vehicleId,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
  });

  /// Record a refuel
  @POST('/app/fleetops/refuels')
  Future<AcceptedEnvelope> recordFleetRefuel({
    @Body() required RecordRefuelRequest body,
  });

  /// Get fuel consumption of a vehicle in a date range
  @GET('/app/fleetops/fuel/consumption')
  Future<GetAppFleetopsFuelConsumptionResponse> getFleetFuelConsumption({
    @Query('vehicle_id') required String vehicleId,
    @Query('from') required DateTime from,
    @Query('to') required DateTime to,
  });

  /// Get fuel spend for a day
  @GET('/app/fleetops/fuel/daily-spend')
  Future<GetAppFleetopsFuelDailySpendResponse> getFleetDailyFuelSpend({
    @Query('date') required DateTime date,
  });

  /// List maintenance orders
  @GET('/app/fleetops/maintenance/orders')
  Future<GetAppFleetopsMaintenanceOrdersResponse> listFleetMaintenanceOrders({
    @Query('vehicle_id') String? vehicleId,
    @Query('status') MaintenanceStatus? status,
  });

  /// Schedule a maintenance order
  @POST('/app/fleetops/maintenance/orders')
  Future<AcceptedEnvelope> scheduleFleetMaintenance({
    @Body() required ScheduleMaintenanceRequest body,
  });

  /// Get a maintenance order
  @GET('/app/fleetops/maintenance/orders/{orderId}')
  Future<GetAppFleetopsMaintenanceOrdersOrderIdResponse>
  getFleetMaintenanceOrder({@Path('orderId') required String orderId});

  /// Start a scheduled maintenance order
  @POST('/app/fleetops/maintenance/orders/{orderId}/start')
  Future<AcceptedEnvelope> startFleetMaintenance({
    @Path('orderId') required String orderId,
  });

  /// Complete a maintenance order with its items
  @POST('/app/fleetops/maintenance/orders/{orderId}/complete')
  Future<AcceptedEnvelope> completeFleetMaintenance({
    @Path('orderId') required String orderId,
    @Body() required CompleteMaintenanceRequest body,
  });

  /// Cancel a maintenance order
  @POST('/app/fleetops/maintenance/orders/{orderId}/cancel')
  Future<AcceptedEnvelope> cancelFleetMaintenance({
    @Path('orderId') required String orderId,
  });

  /// List maintenance plans
  @GET('/app/fleetops/maintenance/plans')
  Future<GetAppFleetopsMaintenancePlansResponse> listFleetMaintenancePlans({
    @Query('vehicle_id') String? vehicleId,
  });

  /// Define a preventive maintenance plan
  @POST('/app/fleetops/maintenance/plans')
  Future<AcceptedEnvelope> defineFleetMaintenancePlan({
    @Body() required DefineMaintenancePlanRequest body,
  });

  /// Record a plan service as done
  @POST('/app/fleetops/maintenance/plans/{planId}/service-done')
  Future<AcceptedEnvelope> recordFleetServiceDone({
    @Path('planId') required String planId,
    @Body() RecordServiceDoneRequest? body,
  });

  /// Activate a maintenance plan
  @POST('/app/fleetops/maintenance/plans/{planId}/activate')
  Future<AcceptedEnvelope> activateFleetMaintenancePlan({
    @Path('planId') required String planId,
  });

  /// Deactivate a maintenance plan
  @POST('/app/fleetops/maintenance/plans/{planId}/deactivate')
  Future<AcceptedEnvelope> deactivateFleetMaintenancePlan({
    @Path('planId') required String planId,
  });

  /// Get maintenance cost of a vehicle in a date range
  @GET('/app/fleetops/maintenance/cost')
  Future<GetAppFleetopsMaintenanceCostResponse> getFleetMaintenanceCost({
    @Query('vehicle_id') required String vehicleId,
    @Query('from') required DateTime from,
    @Query('to') required DateTime to,
  });

  /// List due or overdue preventive maintenance
  @GET('/app/fleetops/maintenance/due')
  Future<GetAppFleetopsMaintenanceDueResponse> listFleetDueMaintenance();

  /// List departures
  @GET('/app/fleetops/departures')
  Future<GetAppFleetopsDeparturesResponse> listFleetDepartures({
    @Query('vehicle_id') String? vehicleId,
    @Query('status') DepartureStatus? status,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
  });

  /// Register a vehicle departure
  @POST('/app/fleetops/departures')
  Future<AcceptedEnvelope> registerFleetDeparture({
    @Body() required RegisterDepartureRequest body,
  });

  /// Get a departure
  @GET('/app/fleetops/departures/{departureId}')
  Future<GetAppFleetopsDeparturesDepartureIdResponse> getFleetDeparture({
    @Path('departureId') required String departureId,
  });

  /// Close a departure on vehicle return
  @POST('/app/fleetops/departures/{departureId}/close')
  Future<AcceptedEnvelope> closeFleetDeparture({
    @Path('departureId') required String departureId,
    @Body() required CloseDepartureRequest body,
  });

  /// List odometer readings
  @GET('/app/fleetops/odometer')
  Future<GetAppFleetopsOdometerResponse> listFleetOdometerReadings({
    @Query('vehicle_id') String? vehicleId,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
  });

  /// Record an odometer reading
  @POST('/app/fleetops/odometer')
  Future<AcceptedEnvelope> recordFleetOdometer({
    @Body() required RecordOdometerRequest body,
  });

  /// Get vehicle utilization in a date range
  @GET('/app/fleetops/utilization')
  Future<GetAppFleetopsUtilizationResponse> getFleetVehicleUtilization({
    @Query('vehicle_id') required String vehicleId,
    @Query('from') required DateTime from,
    @Query('to') required DateTime to,
  });

  /// List vehicle technical profiles
  @GET('/app/fleetops/vehicle-profiles')
  Future<GetAppFleetopsVehicleProfilesResponse> listFleetVehicleProfiles();

  /// Define a vehicle technical profile (upsert)
  @POST('/app/fleetops/vehicle-profiles')
  Future<AcceptedEnvelope> defineFleetVehicleProfile({
    @Body() required DefineVehicleProfileRequest body,
  });

  /// Get a vehicle technical profile
  @GET('/app/fleetops/vehicle-profiles/{vehicleId}')
  Future<GetAppFleetopsVehicleProfilesVehicleIdResponse>
  getFleetVehicleProfile({@Path('vehicleId') required String vehicleId});

  /// Set the current odometer of a vehicle
  @POST('/app/fleetops/vehicle-profiles/{vehicleId}/odometer')
  Future<AcceptedEnvelope> updateFleetVehicleOdometer({
    @Path('vehicleId') required String vehicleId,
    @Body() required UpdateVehicleOdometerRequest body,
  });

  /// List fleet expenses
  @GET('/app/fleetops/expenses')
  Future<GetAppFleetopsExpensesResponse> listFleetExpenses({
    @Query('vehicle_id') String? vehicleId,
    @Query('category') ExpenseCategory? category,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
  });

  /// Record a fleet expense
  @POST('/app/fleetops/expenses')
  Future<AcceptedEnvelope> recordFleetExpense({
    @Body() required RecordExpenseRequest body,
  });

  /// Get the total expenses of a vehicle
  @GET('/app/fleetops/expenses/total')
  Future<GetAppFleetopsExpensesTotalResponse> getFleetVehicleExpenseTotal({
    @Query('vehicle_id') required String vehicleId,
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
  });

  /// Get the cost summary (TCO + cost per km) of a vehicle
  @GET('/app/fleetops/cost-summary')
  Future<GetAppFleetopsCostSummaryResponse> getFleetVehicleCostSummary({
    @Query('vehicle_id') required String vehicleId,
    @Query('from') required DateTime from,
    @Query('to') required DateTime to,
  });

  /// Record a refuel from a fuel-card or station system.
  ///
  /// Ingesta de una carga de combustible desde sistemas de tarjeta/estación (credenciales de servicio).
  @POST('/integrations/fleetops/refuels')
  Future<AcceptedEnvelope> integrationRecordFleetRefuel({
    @Body() required RecordRefuelRequest body,
  });

  /// Record an odometer reading from telemetry.
  ///
  /// Ingesta de una lectura de odómetro desde telemetría o sistemas externos (credenciales de servicio).
  @POST('/integrations/fleetops/odometer')
  Future<AcceptedEnvelope> integrationRecordFleetOdometer({
    @Body() required RecordOdometerRequest body,
  });
}
