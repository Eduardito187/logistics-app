// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/discard_outbox_message_request.dart';
import '../models/outbox_action_envelope.dart';
import '../models/outbox_message_envelope.dart';
import '../models/outbox_message_page.dart';
import '../models/outbox_stats_envelope.dart';
import '../models/outbox_status.dart';
import '../models/relay_outbox_request.dart';
import '../models/relay_outbox_result_envelope.dart';

part 'outbox_client.g.dart';

@RestApi()
abstract class OutboxClient {
  factory OutboxClient(Dio dio, {String? baseUrl}) = _OutboxClient;

  /// List outbox messages (internal app).
  ///
  /// Paginated list of outbox messages for the operations control tower, optionally filtered by status (pending, failed, dispatched, dead_lettered).
  ///
  /// [status] - Filter by message status.
  ///
  /// [page] - 1-based page number.
  ///
  /// [perPage] - Page size (max 200).
  @GET('/app/outbox/messages')
  Future<OutboxMessagePage> appListOutboxMessages({
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 25,
    @Query('status') OutboxStatus? status,
  });

  /// Outbox message counts by status (internal app).
  ///
  /// Count of messages per status plus the live backlog (pending + failed).
  @GET('/app/outbox/messages/stats')
  Future<OutboxStatsEnvelope> appGetOutboxStats();

  /// Get one outbox message (internal app).
  ///
  /// Full detail of a message, including its payload and last error.
  ///
  /// [id] - Outbox message id (UUID v7).
  @GET('/app/outbox/messages/{id}')
  Future<OutboxMessageEnvelope> appGetOutboxMessage({
    @Path('id') required String id,
  });

  /// Discard an outbox message (internal app).
  ///
  /// Manually sends a dispatchable message to dead-letter with an audit reason, without waiting for the retries to run out.
  ///
  /// [id] - Outbox message id (UUID v7).
  @POST('/app/outbox/messages/{id}/discard')
  Future<OutboxActionEnvelope> appDiscardOutboxMessage({
    @Path('id') required String id,
    @Body() required DiscardOutboxMessageRequest body,
  });

  /// Requeue an outbox message (internal app).
  ///
  /// Requeues a failed or dead-lettered message so the relay dispatches it again. Resets the retry counter and makes it available immediately. Rejected for already dispatched messages.
  ///
  /// [id] - Outbox message id (UUID v7).
  @POST('/app/outbox/messages/{id}/retry')
  Future<OutboxActionEnvelope> appRetryOutboxMessage({
    @Path('id') required String id,
  });

  /// Dispatch a batch of outbox messages (integrations).
  ///
  /// Runs the relay on demand (besides the scheduler). Dispatches up to `limit` dispatchable messages and returns the run summary.
  @POST('/integrations/outbox/relay')
  Future<RelayOutboxResultEnvelope> integrationsRelayOutbox({
    @Body() RelayOutboxRequest? body,
  });

  /// Outbox message counts by status (integrations).
  ///
  /// Monitoring endpoint for services: message counts per status and backlog.
  @GET('/integrations/outbox/stats')
  Future<OutboxStatsEnvelope> integrationsGetOutboxStats();
}
