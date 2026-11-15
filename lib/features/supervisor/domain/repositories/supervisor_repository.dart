import '../../../../core/api/models/trip_candidate_list.dart';
import '../../../../core/api/models/trip_sequence_suggestion.dart';
import '../../../../core/api/models/alert.dart';
import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/api/models/get_plan_eta_data.dart';
import '../../../../core/api/models/generate_daily_plan_request_strategy.dart';
import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/stops3.dart';
import '../../../../core/api/models/strategy.dart';
import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/api/models/vehicle_telemetry_summary.dart';

/// Contrato de acceso a datos del supervisor. La capa de `data` lo implementa;
/// los casos de uso dependen de esta interfaz, no del cliente API.
abstract interface class SupervisorRepository {
  /// Posiciones en vivo de toda la flota.
  Future<List<VehicleLive>> getLiveFleetPositions();

  /// Alertas de telemetría; `acknowledged` filtra por estado de reconocimiento.
  Future<List<Alert>> listTelemetryAlerts({bool? acknowledged});

  /// Resumen diario de telemetría de un vehículo.
  Future<VehicleTelemetrySummary> getVehicleTelemetrySummary(String vehicleId);

  /// Placa de cada camión de la flota, por id de vehículo.
  Future<Map<String, String>> getVehiclePlates();

  /// Reconoce una alerta de telemetría (requiere red).
  Future<void> acknowledgeTelemetryAlert(String alertId);

  /// Lista de envíos (para el agregado del tablero).
  Future<List<Shipment>> listShipments();

  /// Planes del día indicado (uno por camión).
  Future<List<Plan>> listPlansByDate(DateTime date);

  /// Detalle de un plan con su secuencia de paradas.
  Future<Plan> getPlan(String planId);

  /// ETA por parada de un plan.
  Future<GetPlanEtaData> getPlanEta(String planId);

  /// Estado y resultado de la corrida automática del día (y modo).
  Future<AutoPlanRun> getDailyPlanRun({
    required DateTime date,
    required Strategy strategy,
  });

  /// Encola la planificación automática del día (job asíncrono).
  Future<AutoPlanRun> generateDailyPlan({
    required DateTime planDate,
    required GenerateDailyPlanRequestStrategy strategy,
  });

  /// Genera una propuesta de plan manual para un camión concreto.
  Future<Plan> generatePlanProposal({
    required DateTime planDate,
    required String vehicleId,
    required DateTime departAt,
    required List<Stops3> stops,
  });

  /// Publica un plan, dejándolo disponible para ejecución.
  Future<void> publishPlan(String planId);

  /// Agrega (o mueve) un envío a este camión como parada nueva.
  Future<void> assignShipmentToPlan({
    required String planId,
    required String shipmentId,
  });

  /// Reordena las paradas de un plan al orden de envíos indicado.
  Future<void> reorderPlanStops({
    required String planId,
    required List<String> orderedShipmentIds,
  });

  /// Pedidos que se pueden sumar al viaje, por cercanía al último elegido (o
  /// a la base del camión).
  Future<TripCandidateList> listTripCandidates({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    List<String> selected,
    String query,
  });

  /// Orden recomendado para esos pedidos. No guarda.
  Future<TripSequenceSuggestion> suggestTripSequence({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    required List<String> shipmentIds,
  });

  /// Crea el viaje (plan en borrador) con las paradas en ese orden.
  Future<Plan> createTrip({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    required List<String> shipmentIds,
  });

  /// Quita una parada de un plan sin publicar.
  Future<void> removeShipmentFromPlan({
    required String planId,
    required String shipmentId,
  });

  /// Borra un plan sin publicar (sus pedidos quedan libres).
  Future<void> deletePlan(String planId);
}
