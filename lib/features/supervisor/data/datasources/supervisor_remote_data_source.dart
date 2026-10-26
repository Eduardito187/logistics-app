import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/alert.dart';
import '../../../../core/api/models/app_plans_plan_id_sequence_request_body.dart';
import '../../../../core/api/models/app_plans_plan_id_stops_request_body.dart';
import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/api/models/data7.dart';
import '../../../../core/api/models/generate_daily_plan_request.dart';
import '../../../../core/api/models/generate_daily_plan_request_strategy.dart';
import '../../../../core/api/models/generate_plan_proposal_request.dart';
import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/stops2.dart';
import '../../../../core/api/models/strategy.dart';
import '../../../../core/api/models/vehicle.dart';
import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/api/models/vehicle_telemetry_summary.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Única clase del feature que toca `logisticsApiProvider` / `api.*`.
///
/// Cada método espeja un endpoint de los módulos de telemetría, planificación y
/// envíos que usa el supervisor, devuelve el modelo generado desde `.data` y
/// normaliza el error de red a [ApiException].
class SupervisorRemoteDataSource {
  SupervisorRemoteDataSource(this._ref);

  final Ref _ref;

  // --- Telemetría (lecturas) ------------------------------------------------

  /// Posiciones en vivo de toda la flota.
  Future<List<VehicleLive>> getLiveFleetPositions() async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .telemetry
          .getLiveFleetPositions();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Alertas de telemetría; `acknowledged` filtra por estado de reconocimiento.
  Future<List<Alert>> listTelemetryAlerts({bool? acknowledged}) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .telemetry
          .listTelemetryAlerts(acknowledged: acknowledged);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Placa de cada camión de la flota, por id de vehículo. Los planes, la
  /// telemetría y las alertas solo traen el id (UUID); la placa es lo que el
  /// supervisor reconoce. Camiones sin placa no entran al mapa.
  Future<Map<String, String>> getVehiclePlates() async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .fleet
          .fleetListVehicles();
      return {
        for (final v in response.data ?? const <Vehicle>[])
          if (v.plate != null && v.plate!.trim().isNotEmpty)
            v.id: v.plate!.trim(),
      };
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Resumen diario de telemetría de un vehículo.
  Future<VehicleTelemetrySummary> getVehicleTelemetrySummary(
    String vehicleId,
  ) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .telemetry
          .getVehicleTelemetrySummary(vehicleId: vehicleId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Telemetría (escritura) -----------------------------------------------

  /// Reconoce una alerta de telemetría (requiere red).
  Future<void> acknowledgeTelemetryAlert(String alertId) async {
    try {
      await _ref
          .read(logisticsApiProvider)
          .telemetry
          .acknowledgeTelemetryAlert(alertId: alertId);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Envíos (lectura) -----------------------------------------------------

  /// Lista de envíos (para el agregado del tablero).
  ///
  /// SIN paginar (`page`/`per_page` en null): el cliente generado manda por
  /// defecto la página 1 de 50 y el tablero contaba como mucho 50 envíos (las
  /// métricas quedaban mal en cuanto la operación pasaba de 50). Sin parámetros
  /// de paginación el backend devuelve la colección completa en 1 request.
  /// No hay filtro de servidor útil: el tablero necesita todos los estados y el
  /// endpoint acepta uno solo. Lo ideal es un endpoint agregado
  /// (`GET /app/dashboard?date=`), pedido al backend.
  Future<List<Shipment>> listShipments() async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .shipments
          .listShipments(page: null, perPage: null);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Planificación (lecturas) ---------------------------------------------

  /// Planes del día indicado (uno por camión).
  Future<List<Plan>> listPlansByDate(DateTime date) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .planning
          .listPlansByDate(date: date);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Detalle de un plan con su secuencia de paradas.
  Future<Plan> getPlan(String planId) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .planning
          .getPlan(planId: planId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// ETA por parada de un plan.
  Future<Data7> getPlanEta(String planId) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .planning
          .getPlanEta(planId: planId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Estado y resultado de la corrida automática del día (y modo).
  Future<AutoPlanRun> getDailyPlanRun({
    required DateTime date,
    required Strategy strategy,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .planning
          .getDailyPlanRun(date: date, strategy: strategy);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // --- Planificación (escrituras) -------------------------------------------

  /// Encola la planificación automática del día (job asíncrono).
  Future<AutoPlanRun> generateDailyPlan({
    required DateTime planDate,
    required GenerateDailyPlanRequestStrategy strategy,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .planning
          .generateDailyPlan(
            body: GenerateDailyPlanRequest(
              planDate: planDate,
              strategy: strategy,
            ),
          );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Genera una propuesta de plan manual para un camión concreto.
  Future<Plan> generatePlanProposal({
    required DateTime planDate,
    required String vehicleId,
    required DateTime departAt,
    required List<Stops2> stops,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .planning
          .generatePlanProposal(
            body: GeneratePlanProposalRequest(
              planDate: planDate,
              vehicleId: vehicleId,
              departAt: departAt,
              stops: stops,
            ),
          );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Publica un plan, dejándolo disponible para ejecución.
  Future<void> publishPlan(String planId) async {
    try {
      await _ref
          .read(logisticsApiProvider)
          .planning
          .publishPlan(planId: planId);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Agrega (o mueve) un envío a este camión como parada nueva.
  Future<void> assignShipmentToPlan({
    required String planId,
    required String shipmentId,
  }) async {
    try {
      await _ref
          .read(logisticsApiProvider)
          .planning
          .assignShipmentToPlan(
            planId: planId,
            body: AppPlansPlanIdStopsRequestBody(shipmentId: shipmentId),
          );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Reordena las paradas de un plan al orden de envíos indicado.
  Future<void> reorderPlanStops({
    required String planId,
    required List<String> orderedShipmentIds,
  }) async {
    try {
      await _ref
          .read(logisticsApiProvider)
          .planning
          .reorderPlanStops(
            planId: planId,
            body: AppPlansPlanIdSequenceRequestBody(
              orderedShipmentIds: orderedShipmentIds,
            ),
          );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final supervisorRemoteDataSourceProvider = Provider<SupervisorRemoteDataSource>(
  SupervisorRemoteDataSource.new,
);
