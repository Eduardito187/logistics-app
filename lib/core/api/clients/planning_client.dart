// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/app_plans_plan_id_sequence_request_body.dart';
import '../models/assign_shipment_to_plan_request.dart';
import '../models/auto_plan_run_envelope.dart';
import '../models/generate_daily_plan_request.dart';
import '../models/generate_plan_proposal_request.dart';
import '../models/get_app_plans_plan_id_eta_response.dart';
import '../models/get_app_plans_response.dart';
import '../models/plan_envelope.dart';
import '../models/status3.dart';
import '../models/strategy.dart';
import '../models/suggest_trip_sequence_request.dart';
import '../models/trip_candidate_list.dart';
import '../models/trip_sequence_suggestion_envelope.dart';

part 'planning_client.g.dart';

@RestApi()
abstract class PlanningClient {
  factory PlanningClient(Dio dio, {String? baseUrl}) = _PlanningClient;

  /// List the delivery plans of a day (one per truck).
  ///
  /// [date] - Day to list, as YYYY-MM-DD. Required unless date_from is given; takes precedence over the range.
  ///
  /// [dateFrom] - First day of a range (inclusive). Required when date is absent or date_to is given.
  ///
  /// [dateTo] - Last day of the range (inclusive). The range may not exceed 31 days.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/plans')
  Future<GetAppPlansResponse> listPlansByDate({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('date') DateTime? date,
    @Query('date_from') DateTime? dateFrom,
    @Query('date_to') DateTime? dateTo,
    @Query('status') Status3? status,
    @Query('vehicle_id') String? vehicleId,
    @Query('cursor') String? cursor,
  });

  /// Create the trip of a truck for a day (stops keep the received order).
  ///
  /// One plan per truck per day. Stops keep the received order unless optimize=true. Stop coordinates are optional (the shipment location is used). A shipment without location, or a trip mixing departments, is rejected with 422 (business_rule_violation, reason in detail).
  @POST('/app/plans')
  Future<PlanEnvelope> generatePlanProposal({
    @Body() required GeneratePlanProposalRequest body,
  });

  /// Shipments that can be added to a truck trip, nearest first.
  ///
  /// Plannable shipments for the day with no truck or plan, in the department of the truck home base and within the caller scope. Sorted by distance to the last selected shipment, or to the truck home base when nothing is selected. Without pagination params the nearest 200 are returned.
  ///
  /// [selected] - Shipments already chosen for the trip, in order. The last one is the distance anchor.
  ///
  /// [q] - Search by order code or customer name.
  ///
  /// [departAt] - Departure time (ISO-8601). Defaults to the configured departure time of the day.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/app/plans/candidates')
  Future<TripCandidateList> listTripCandidates({
    @Query('date') required DateTime date,
    @Query('vehicle_id') required String vehicleId,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('selected') List<String>? selected,
    @Query('q') String? q,
    @Query('depart_at') DateTime? departAt,
    @Query('cursor') String? cursor,
  });

  /// Suggested delivery order for a trip (shortest path honouring customer time windows).
  ///
  /// Read-only. Nothing is stored; the planner accepts the order or not.
  @POST('/app/plans/suggest-sequence')
  Future<TripSequenceSuggestionEnvelope> suggestTripSequence({
    @Body() required SuggestTripSequenceRequest body,
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
    @Body() required AssignShipmentToPlanRequest body,
  });

  /// Remove a stop from an unpublished plan
  @DELETE('/app/plans/{planId}/stops/{shipmentId}')
  Future<PlanEnvelope> removeShipmentFromPlan({
    @Path('planId') required String planId,
    @Path('shipmentId') required String shipmentId,
  });
}
