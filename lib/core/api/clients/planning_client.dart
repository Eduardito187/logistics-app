// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_plans_plan_id_sequence_request_body.dart';
import '../models/app_plans_plan_id_stops_request_body.dart';
import '../models/auto_plan_run_envelope.dart';
import '../models/generate_daily_plan_request.dart';
import '../models/generate_plan_proposal_request.dart';
import '../models/get_app_plans_plan_id_eta_response.dart';
import '../models/get_app_plans_response.dart';
import '../models/plan_envelope.dart';
import '../models/strategy.dart';

part 'planning_client.g.dart';

@RestApi()
abstract class PlanningClient {
  factory PlanningClient(Dio dio, {String? baseUrl}) = _PlanningClient;

  /// List the delivery plans of a day (one per truck).
  ///
  /// [date] - Day to list, as YYYY-MM-DD.
  @GET('/app/plans')
  Future<GetAppPlansResponse> listPlansByDate({
    @Query('date') required DateTime date,
  });

  /// Generate the automatic order-to-truck proposal for a day
  @POST('/app/plans')
  Future<PlanEnvelope> generatePlanProposal({
    @Body() required GeneratePlanProposalRequest body,
  });

  /// Status and result of the day's auto-plan run.
  ///
  /// [date] - Day of the run, as YYYY-MM-DD.
  ///
  /// [strategy] - Planning mode.
  @GET('/app/plans/auto')
  Future<AutoPlanRunEnvelope> getDailyPlanRun({
    @Query('date') required DateTime date,
    @Query('strategy') required Strategy strategy,
  });

  /// Auto-plan the whole day (asynchronous).
  ///
  /// Queues the heavy auto-planning work (packing into trucks, proximity routing and the load plan) for the pending orders of a day. Returns the queued run; the result is polled with GET /app/plans/auto. Idempotent: re-triggering the same day and mode returns the existing run.
  @POST('/app/plans/auto')
  Future<AutoPlanRunEnvelope> generateDailyPlan({
    @Body() required GenerateDailyPlanRequest body,
  });

  /// Get a plan with its stop sequence, ETA and load plan
  @GET('/app/plans/{planId}')
  Future<PlanEnvelope> getPlan({@Path('planId') required String planId});

  /// ETA per stop of the plan
  @GET('/app/plans/{planId}/eta')
  Future<GetAppPlansPlanIdEtaResponse> getPlanEta({
    @Path('planId') required String planId,
  });

  /// Publish the plan, making it available to execution
  @POST('/app/plans/{planId}/publish')
  Future<PlanEnvelope> publishPlan({@Path('planId') required String planId});

  /// Reorder the plan stops to the given order
  @PUT('/app/plans/{planId}/sequence')
  Future<PlanEnvelope> reorderPlanStops({
    @Path('planId') required String planId,
    @Body() required AppPlansPlanIdSequenceRequestBody body,
  });

  /// Manual adjustment — add or move a shipment onto this truck
  @POST('/app/plans/{planId}/stops')
  Future<PlanEnvelope> assignShipmentToPlan({
    @Path('planId') required String planId,
    @Body() required AppPlansPlanIdStopsRequestBody body,
  });
}
