// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/advance_cascade_envelope.dart';
import '../models/get_app_notification_rules_response.dart';
import '../models/get_app_notification_sms_budget_response.dart';
import '../models/get_app_notification_templates_response.dart';
import '../models/get_app_notifications_notification_response.dart';
import '../models/notification_list_envelope.dart';
import '../models/put_app_notification_rules_response.dart';
import '../models/queue_notification_request.dart';
import '../models/queued_notification_envelope.dart';
import '../models/set_message_type_rule_request.dart';
import '../models/upsert_message_template_request.dart';

part 'notifications_client.g.dart';

@RestApi()
abstract class NotificationsClient {
  factory NotificationsClient(Dio dio, {String? baseUrl}) =
      _NotificationsClient;

  /// List the cascade rule per message type (internal app)
  @GET('/app/notification-rules')
  Future<GetAppNotificationRulesResponse> appListNotificationRules();

  /// Configure the cascade of a message type (internal app)
  @PUT('/app/notification-rules')
  Future<PutAppNotificationRulesResponse> appSetNotificationRule({
    @Body() required SetMessageTypeRuleRequest body,
  });

  /// Get the monthly SMS budget (internal app).
  ///
  /// App gate. Returns the SMS budget of a period (YYYY-MM); defaults to the current month.
  @GET('/app/notification-sms-budget')
  Future<GetAppNotificationSmsBudgetResponse> appGetSmsBudget({
    @Query('period') String? period,
  });

  /// List message templates (internal app)
  @GET('/app/notification-templates')
  Future<GetAppNotificationTemplatesResponse> appListMessageTemplates();

  /// Create or update a message template (internal app)
  @PUT('/app/notification-templates')
  Future<void> appUpsertMessageTemplate({
    @Body() required UpsertMessageTemplateRequest body,
  });

  /// List a shipment's notifications (internal app).
  ///
  /// Returns the notification log of a shipment, newest first. App gate (operations/support visibility). The shipment id is passed as a query parameter.
  @GET('/app/notifications')
  Future<NotificationListEnvelope> appListShipmentNotifications({
    @Query('shipment_id') required String shipmentId,
  });

  /// List the global notification log (internal app).
  ///
  /// Returns the latest notifications across the whole operation, newest first. App gate.
  @GET('/app/notifications/all')
  Future<NotificationListEnvelope> appListNotifications({
    @Query('limit') int? limit = 100,
  });

  /// Get a single notification (internal app)
  @GET('/app/notifications/{notification}')
  Future<GetAppNotificationsNotificationResponse> appGetNotification({
    @Path('notification') required String notification,
  });

  /// Suppress a queued notification (internal app).
  ///
  /// App gate. Suppresses a queued notification so it no longer walks the cascade. Responds 202.
  @POST('/app/notifications/{notification}/suppress')
  Future<void> appSuppressNotification({
    @Path('notification') required String notification,
  });

  /// List a shipment's notifications (customer channels).
  ///
  /// Returns the notification history of a shipment, newest first. Channels gate (customer web / call center). The shipment id is a path parameter.
  @GET('/channels/shipments/{shipment}/notifications')
  Future<NotificationListEnvelope> channelsListShipmentNotifications({
    @Path('shipment') required String shipment,
  });

  /// Queue a notification for a shipment.
  ///
  /// Integrations gate (service credentials). Queues a customer notification for a shipment; the message type resolves the channel cascade. Delivery happens asynchronously via the outbox, so the response is 202 Accepted.
  @POST('/integrations/notifications')
  Future<QueuedNotificationEnvelope> integrationsQueueNotification({
    @Body() required QueueNotificationRequest body,
  });

  /// Advance a notification's channel cascade.
  ///
  /// Integrations gate. Called by the outbox relay or an open/delivery callback to escalate the notification to the next channel when the current one was not opened. Processed via the outbox, so the response is 202 Accepted.
  @POST('/integrations/notifications/{notification}/advance-cascade')
  Future<AdvanceCascadeEnvelope> integrationsAdvanceCascade({
    @Path('notification') required String notification,
  });
}
