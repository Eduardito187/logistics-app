import 'package:logistics_app/core/api/models/alert.dart';
import 'package:logistics_app/core/api/models/auto_plan_run.dart';
import 'package:logistics_app/core/api/models/data7.dart';
import 'package:logistics_app/core/api/models/generate_daily_plan_request_strategy.dart';
import 'package:logistics_app/core/api/models/plan.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/stops2.dart';
import 'package:logistics_app/core/api/models/strategy.dart';
import 'package:logistics_app/core/api/models/vehicle_live.dart';
import 'package:logistics_app/core/api/models/vehicle_telemetry_summary.dart';
import 'package:logistics_app/features/supervisor/domain/repositories/supervisor_repository.dart';

/// Repositorio falso del supervisor para tests: devuelve valores en memoria y,
/// si el `*Error` correspondiente está seteado, lo lanza (para probar el estado
/// de error). Registra argumentos/llamadas para las aserciones.
///
/// Las operaciones de escritura (generar/publicar/asignar/reordenar) lanzan
/// [UnimplementedError]: la app de campo del supervisor es SOLO lectura; esas
/// acciones son de oficina (admin del backend) y ninguna pantalla debe llamarlas.
class FakeSupervisorRepository implements SupervisorRepository {
  // Flota en vivo.
  List<VehicleLive> fleet = const [];
  Object? fleetError;
  int fleetCalls = 0;

  // Alertas de telemetría.
  List<Alert> alerts = const [];
  Object? alertsError;
  bool? lastAlertsAcknowledgedArg;
  int listAlertsCalls = 0;

  // Reconocimiento de alertas.
  final List<String> acknowledgedIds = [];
  Object? acknowledgeError;

  // Tablero (envíos + planes + alertas).
  List<Shipment> shipments = const [];
  List<Plan> plansByDate = const [];
  Object? shipmentsError;
  Object? plansError;
  DateTime? lastPlansDate;
  int shipmentsCalls = 0;
  int plansCalls = 0;

  /// Si se setea, las lecturas del tablero esperan a este completer (para
  /// probar que salen en paralelo: las tres quedan en vuelo a la vez).
  Future<void>? dashboardGate;

  // Resumen de telemetría por vehículo.
  VehicleTelemetrySummary? vehicleSummaryValue;
  Object? vehicleSummaryError;

  // Detalle de plan y ETA.
  Plan? planValue;
  Object? planError;
  Data7? planEtaValue;
  Object? planEtaError;
  int planCalls = 0;
  int planEtaCalls = 0;

  /// Si se setea, `getPlan` espera a este future (detalle "cargando").
  Future<void>? planGate;

  @override
  Future<List<VehicleLive>> getLiveFleetPositions() async {
    fleetCalls++;
    if (fleetError != null) throw fleetError!;
    return fleet;
  }

  @override
  Future<List<Alert>> listTelemetryAlerts({bool? acknowledged}) async {
    listAlertsCalls++;
    lastAlertsAcknowledgedArg = acknowledged;
    await dashboardGate;
    if (alertsError != null) throw alertsError!;
    return alerts;
  }

  @override
  Future<VehicleTelemetrySummary> getVehicleTelemetrySummary(
    String vehicleId,
  ) async {
    if (vehicleSummaryError != null) throw vehicleSummaryError!;
    return vehicleSummaryValue!;
  }

  // Placas de la flota por id de vehículo.
  Map<String, String> plates = const {};

  int platesCalls = 0;

  @override
  Future<Map<String, String>> getVehiclePlates() async {
    platesCalls++;
    return plates;
  }

  @override
  Future<void> acknowledgeTelemetryAlert(String alertId) async {
    if (acknowledgeError != null) throw acknowledgeError!;
    acknowledgedIds.add(alertId);
  }

  @override
  Future<List<Shipment>> listShipments() async {
    shipmentsCalls++;
    await dashboardGate;
    if (shipmentsError != null) throw shipmentsError!;
    return shipments;
  }

  @override
  Future<List<Plan>> listPlansByDate(DateTime date) async {
    plansCalls++;
    lastPlansDate = date;
    await dashboardGate;
    if (plansError != null) throw plansError!;
    return plansByDate;
  }

  @override
  Future<Plan> getPlan(String planId) async {
    planCalls++;
    await planGate;
    if (planError != null) throw planError!;
    return planValue!;
  }

  @override
  Future<Data7> getPlanEta(String planId) async {
    planEtaCalls++;
    if (planEtaError != null) throw planEtaError!;
    return planEtaValue!;
  }

  // --- Escrituras NO usadas por la app de campo (solo lectura). ---

  @override
  Future<AutoPlanRun> getDailyPlanRun({
    required DateTime date,
    required Strategy strategy,
  }) => throw UnimplementedError('No usado por la app (solo lectura).');

  @override
  Future<AutoPlanRun> generateDailyPlan({
    required DateTime planDate,
    required GenerateDailyPlanRequestStrategy strategy,
  }) => throw UnimplementedError('No usado por la app (solo lectura).');

  @override
  Future<Plan> generatePlanProposal({
    required DateTime planDate,
    required String vehicleId,
    required DateTime departAt,
    required List<Stops2> stops,
  }) => throw UnimplementedError('No usado por la app (solo lectura).');

  @override
  Future<void> publishPlan(String planId) =>
      throw UnimplementedError('No usado por la app (solo lectura).');

  @override
  Future<void> assignShipmentToPlan({
    required String planId,
    required String shipmentId,
  }) => throw UnimplementedError('No usado por la app (solo lectura).');

  @override
  Future<void> reorderPlanStops({
    required String planId,
    required List<String> orderedShipmentIds,
  }) => throw UnimplementedError('No usado por la app (solo lectura).');
}
