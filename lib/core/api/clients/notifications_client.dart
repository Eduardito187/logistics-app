// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/advance_cascade_envelope.dart';
import '../models/app_notifications_read_all_request_body.dart';
import '../models/get_app_notification_rules_response.dart';
import '../models/get_app_notification_sms_budget_response.dart';
import '../models/get_app_notification_templates_response.dart';
import '../models/get_app_notifications_all_response.dart';
import '../models/get_app_notifications_notification_response.dart';
import '../models/notification_list_envelope.dart';
import '../models/post_app_notifications_notification_read_response.dart';
import '../models/post_app_notifications_read_all_response.dart';
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
  /// Alcance por rol: solo se ven las notificaciones de envíos que el usuario puede ver (misma regla que los pedidos: admin/supervisor sin restricción; preparador/planificador por ciudad de origen o destino; tienda por su nodo; chofer/transportista por asignación). Los totales y el no-leído cuentan solo lo visible; una notificación fuera de alcance responde 404 y un envío fuera de alcance devuelve lista vacía.
  @GET('/app/notifications')
  Future<NotificationListEnvelope> appListShipmentNotifications({
    @Query('shipment_id') required String shipmentId,
  });

  /// List the global notification log (internal app).
  ///
  /// Returns the latest notifications across the whole operation, newest first. App gate.
  /// Alcance por rol: solo se ven las notificaciones de envíos que el usuario puede ver (misma regla que los pedidos: admin/supervisor sin restricción; preparador/planificador por ciudad de origen o destino; tienda por su nodo; chofer/transportista por asignación). Los totales y el no-leído cuentan solo lo visible; una notificación fuera de alcance responde 404 y un envío fuera de alcance devuelve lista vacía.
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  ///
  /// [unread] - When true, only notifications the authenticated user has not read (meta.total counts unread).
  @GET('/app/notifications/all')
  Future<GetAppNotificationsAllResponse> appListNotifications({
    @Query('cursor') String? cursor,
    @Query('unread') bool? unread,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
  });

  /// Mark all notifications as read for the authenticated user
  @POST('/app/notifications/read-all')
  Future<PostAppNotificationsReadAllResponse> appMarkAllNotificationsRead({
    @Body() AppNotificationsReadAllRequestBody? body,
  });

  /// Mark a notification as read for the authenticated user (idempotent)
  @POST('/app/notifications/{notification}/read')
  Future<PostAppNotificationsNotificationReadResponse> appMarkNotificationRead({
    @Path('notification') required String notification,
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
