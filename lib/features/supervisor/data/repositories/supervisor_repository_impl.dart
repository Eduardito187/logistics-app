import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/alert.dart';
import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/api/models/data6.dart';
import '../../../../core/api/models/generate_daily_plan_request_strategy.dart';
import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/stops2.dart';
import '../../../../core/api/models/strategy.dart';
import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/api/models/vehicle_telemetry_summary.dart';
import '../../domain/repositories/supervisor_repository.dart';
import '../datasources/supervisor_remote_data_source.dart';

/// Implementación del contrato del supervisor: delega en el data source remoto,
/// que es quien habla con el cliente API.
class SupervisorRepositoryImpl implements SupervisorRepository {
  SupervisorRepositoryImpl(this._remote);

  final SupervisorRemoteDataSource _remote;

  @override
  Future<List<VehicleLive>> getLiveFleetPositions() =>
      _remote.getLiveFleetPositions();

  @override
  Future<List<Alert>> listTelemetryAlerts({bool? acknowledged}) =>
      _remote.listTelemetryAlerts(acknowledged: acknowledged);

  @override
  Future<VehicleTelemetrySummary> getVehicleTelemetrySummary(
    String vehicleId,
  ) => _remote.getVehicleTelemetrySummary(vehicleId);

  @override
  Future<void> acknowledgeTelemetryAlert(String alertId) =>
      _remote.acknowledgeTelemetryAlert(alertId);

  @override
  Future<List<Shipment>> listShipments() => _remote.listShipments();

  @override
  Future<List<Plan>> listPlansByDate(DateTime date) =>
      _remote.listPlansByDate(date);

  @override
  Future<Plan> getPlan(String planId) => _remote.getPlan(planId);

  @override
  Future<Data6> getPlanEta(String planId) => _remote.getPlanEta(planId);

  @override
  Future<AutoPlanRun> getDailyPlanRun({
    required DateTime date,
    required Strategy strategy,
  }) => _remote.getDailyPlanRun(date: date, strategy: strategy);

  @override
  Future<AutoPlanRun> generateDailyPlan({
    required DateTime planDate,
    required GenerateDailyPlanRequestStrategy strategy,
  }) => _remote.generateDailyPlan(planDate: planDate, strategy: strategy);

  @override
  Future<Plan> generatePlanProposal({
    required DateTime planDate,
    required String vehicleId,
    required DateTime departAt,
    required List<Stops2> stops,
  }) => _remote.generatePlanProposal(
    planDate: planDate,
    vehicleId: vehicleId,
    departAt: departAt,
    stops: stops,
  );

  @override
  Future<void> publishPlan(String planId) => _remote.publishPlan(planId);

  @override
  Future<void> assignShipmentToPlan({
    required String planId,
    required String shipmentId,
  }) => _remote.assignShipmentToPlan(planId: planId, shipmentId: shipmentId);

  @override
  Future<void> reorderPlanStops({
    required String planId,
    required List<String> orderedShipmentIds,
  }) => _remote.reorderPlanStops(
    planId: planId,
    orderedShipmentIds: orderedShipmentIds,
  );
}

/// Provider del repositorio expuesto con el **tipo interfaz**: la presentación
/// y los casos de uso nunca ven la implementación concreta.
final supervisorRepositoryProvider = Provider<SupervisorRepository>(
  (ref) =>
      SupervisorRepositoryImpl(ref.watch(supervisorRemoteDataSourceProvider)),
);
