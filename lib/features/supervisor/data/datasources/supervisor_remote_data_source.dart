import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/alert.dart';
import '../../../../core/api/models/app_plans_plan_id_sequence_request_body.dart';
import '../../../../core/api/models/assign_shipment_to_plan_request.dart';
import '../../../../core/api/models/auto_plan_run.dart';
import '../../../../core/api/models/auto_plan_run_envelope.dart';
import '../../../../core/api/models/get_plan_eta_data.dart';
import '../../../../core/api/models/generate_daily_plan_request.dart';
import '../../../../core/api/models/generate_daily_plan_request_strategy.dart';
import '../../../../core/api/models/generate_plan_proposal_request.dart';
import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/plan_envelope.dart';
import '../../../../core/api/models/trip_candidate_list.dart';
import '../../../../core/api/models/trip_sequence_suggestion.dart';
import '../../../../core/api/models/trip_sequence_suggestion_envelope.dart';
import '../../domain/trip_already_planned.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/stops3.dart';
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
          if (v.id != null && v.plate != null && v.plate!.trim().isNotEmpty)
            v.id!: v.plate!.trim(),
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
  Future<GetPlanEtaData> getPlanEta(String planId) async {
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
    // El backend valida `plan_date` como `Y-m-d` estricto y el cliente
    // generado manda fecha-hora ISO: va por Dio directo, reusando los modelos
    // generados para armar el cuerpo y leer la respuesta.
    final body =
        GenerateDailyPlanRequest(
            planDate: planDate,
            strategy: strategy,
          ).toJson()
          ..['plan_date'] =
              '${planDate.year.toString().padLeft(4, '0')}-'
              '${planDate.month.toString().padLeft(2, '0')}-'
              '${planDate.day.toString().padLeft(2, '0')}'
          ..removeWhere((key, value) => value == null);
    try {
      final response = await _ref
          .read(dioProvider)
          .post<Map<String, Object?>>('/app/plans/auto', data: body);
      return AutoPlanRunEnvelope.fromJson(response.data!).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Genera una propuesta de plan manual para un camión concreto.
  Future<Plan> generatePlanProposal({
    required DateTime planDate,
    required String vehicleId,
    required DateTime departAt,
    required List<Stops3> stops,
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
            body: AssignShipmentToPlanRequest(shipmentId: shipmentId),
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

extension SupervisorTripPlanning on SupervisorRemoteDataSource {
  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // Estos tres van por Dio directo: llevan fechas de calendario (`Y-m-d`) y
  // la lista `selected` separada por comas, que el cliente generado serializa
  // de otra forma. Las respuestas se leen con los modelos generados.

  /// Pedidos que se pueden sumar al viaje, ordenados por cercanía al último
  /// elegido (o a la base del camión si todavía no hay ninguno).
  Future<TripCandidateList> listTripCandidates({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    List<String> selected = const [],
    String query = '',
  }) async {
    try {
      final res = await _ref
          .read(dioProvider)
          .get<Map<String, Object?>>(
            '/app/plans/candidates',
            queryParameters: <String, Object?>{
              'date': _ymd(date),
              'vehicle_id': vehicleId,
              'depart_at': departAt.toUtc().toIso8601String(),
              if (selected.isNotEmpty) 'selected': selected.join(','),
              if (query.isNotEmpty) 'q': query,
              'per_page': 50,
            },
          );
      return TripCandidateList.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Orden que recomienda el backend para esos pedidos (camino más corto
  /// respetando la hora que pidió cada cliente). No guarda nada.
  Future<TripSequenceSuggestion> suggestTripSequence({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    required List<String> shipmentIds,
  }) async {
    try {
      final res = await _ref
          .read(dioProvider)
          .post<Map<String, Object?>>(
            '/app/plans/suggest-sequence',
            data: <String, Object?>{
              'date': _ymd(date),
              'vehicle_id': vehicleId,
              'depart_at': departAt.toUtc().toIso8601String(),
              'shipment_ids': shipmentIds,
            },
          );
      return TripSequenceSuggestionEnvelope.fromJson(res.data!).data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Crea el viaje (plan en borrador) con las paradas EN ESE ORDEN. Si el
  /// camión ya tiene plan ese día lanza [TripAlreadyPlanned] con su id.
  Future<Plan> createTrip({
    required DateTime date,
    required String vehicleId,
    required DateTime departAt,
    required List<String> shipmentIds,
  }) async {
    try {
      final res = await _ref
          .read(dioProvider)
          .post<Map<String, Object?>>(
            '/app/plans',
            data: <String, Object?>{
              'plan_date': _ymd(date),
              'vehicle_id': vehicleId,
              'depart_at': departAt.toUtc().toIso8601String(),
              'stops': [
                for (final id in shipmentIds) {'shipment_id': id},
              ],
            },
          );
      return PlanEnvelope.fromJson(res.data!).data;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (e.response?.statusCode == 409 && body is Map) {
        final planId = body['plan_id'];
        if (planId is String) throw TripAlreadyPlanned(planId);
      }
      throw ApiException.fromDio(e);
    }
  }

  /// Quita una parada de un plan sin publicar.
  Future<void> removeShipmentFromPlan({
    required String planId,
    required String shipmentId,
  }) async {
    try {
      await _ref
          .read(logisticsApiProvider)
          .planning
          .removeShipmentFromPlan(planId: planId, shipmentId: shipmentId);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Borra un plan SIN publicar; sus pedidos quedan libres para otro viaje.
  /// El backend responde 409 si ya está publicado.
  Future<void> deletePlan(String planId) async {
    try {
      await _ref.read(dioProvider).delete<void>('/app/plans/$planId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final supervisorRemoteDataSourceProvider = Provider<SupervisorRemoteDataSource>(
  SupervisorRemoteDataSource.new,
);
