import 'package:logistics_app/core/api/models/alert.dart';
import 'package:logistics_app/core/api/models/auto_plan_run.dart';
import 'package:logistics_app/core/api/models/get_plan_eta_data.dart';
import 'package:logistics_app/core/api/models/generate_daily_plan_request_strategy.dart';
import 'package:logistics_app/core/api/models/plan.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/stops3.dart';
import 'package:logistics_app/core/api/models/strategy.dart';
import 'package:logistics_app/core/api/models/trip_candidate_list.dart';
import 'package:logistics_app/core/api/models/trip_sequence_suggestion.dart';
import 'package:logistics_app/core/api/models/vehicle_live.dart';
import 'package:logistics_app/core/api/models/vehicle_telemetry_summary.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/domain/repositories/supervisor_repository.dart';

/// Repositorio falso del supervisor para tests: devuelve valores en memoria y,
/// si el `*Error` correspondiente está seteado, lo lanza (para probar el estado
/// de error). Registra argumentos/llamadas para las aserciones.
///
/// Las escrituras de planificación (planificar/publicar/asignar/reordenar) se
/// registran: solo las usan el planificador y el administrador; el supervisor
/// es SOLO lectura y ninguna de sus pantallas debe llamarlas.
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
  GetPlanEtaData? planEtaValue;
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
  Future<GetPlanEtaData> getPlanEta(String planId) async {
    planEtaCalls++;
    if (planEtaError != null) throw planEtaError!;
    return planEtaValue!;
  }

  // --- Planificación (planificador / administrador). ---

  /// Corrida automática del día; `null` = ese día no se planificó (404).
  AutoPlanRun? run;

  /// Corrida que devuelve "planificar el día" (y queda como [run]).
  AutoPlanRun? runAfterGenerate;
  final List<DateTime> generatedDays = [];
  final List<String> publishedIds = [];
  final List<({String planId, String shipmentId})> assigned = [];
  final List<({String planId, List<String> order})> reordered = [];
  Object? writeError;

  @override
  Future<AutoPlanRun> getDailyPlanRun({
    required DateTime date,
    required Strategy strategy,
  }) async {
    final current = run;
    if (current == null) {
      throw const ApiException(status: 404, title: 'Sin corrida');
    }
    return current;
  }

  @override
  Future<AutoPlanRun> generateDailyPlan({
    required DateTime planDate,
    required GenerateDailyPlanRequestStrategy strategy,
  }) async {
    if (writeError != null) throw writeError!;
    generatedDays.add(planDate);
    return run = runAfterGenerate!;
  }

  @override
  Future<Plan> generatePlanProposal({
    required DateTime planDate,
    required String vehicleId,
    required DateTime departAt,
    required List<Stops3> stops,
  }) => throw UnimplementedError('No usado por la app.');

  @override
  Future<void> publishPlan(String planId) async {
    if (writeError != null) throw writeError!;
    publishedIds.add(planId);
  }

  @override
  Future<void> assignShipmentToPlan({
    required String planId,
    required String shipmentId,
  }) async {
    if (writeError != null) throw writeError!;
    assigned.add((planId: planId, shipmentId: shipmentId));
  }

  @override
  Future<void> reorderPlanStops({
    required String planId,
    required List<String> orderedShipmentIds,
  }) async {
    if (writeError != null) throw writeError!;
    reordered.add((planId: planId, order: orderedShipmentIds));
  }

  // --- Armado de viajes. ---

  /// Pedidos cercanos que devuelve el backend, según lo ya elegido.
  TripCandidateList Function(List<String> selected, String query)? candidates;
  TripSequenceSuggestion? suggestion;
  final List<List<String>> candidateCalls = [];
  final List<List<String>> suggestionCalls = [];
  final List<({String vehicleId, List<String> shipmentIds})> createdTrips = [];
  final List<({String planId, String shipmentId})> removed = [];

  /// Si se setea, crear el viaje falla con esto (p. ej. [TripAlreadyPlanned]).
  Object? createTripError;

  @override
  Future<TripCandidateList> listTripCandidates({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    List<String> selected = const [],
    String query = '',
  }) async {
    candidateCalls.add(selected);
    return candidates!(selected, query);
  }

  @override
  Future<TripSequenceSuggestion> suggestTripSequence({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    required List<String> shipmentIds,
  }) async {
    suggestionCalls.add(shipmentIds);
    return suggestion!;
  }

  @override
  Future<Plan> createTrip({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    required List<String> shipmentIds,
  }) async {
    if (createTripError != null) throw createTripError!;
    createdTrips.add((vehicleId: vehicleId, shipmentIds: shipmentIds));
    return planValue!;
  }

  @override
  Future<void> removeShipmentFromPlan({
    required String planId,
    required String shipmentId,
  }) async {
    if (writeError != null) throw writeError!;
    removed.add((planId: planId, shipmentId: shipmentId));
  }
}
