// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/accepted_envelope.dart';
import '../models/app_delivery_calendar_blocked_request_body.dart';
import '../models/app_delivery_calendar_blocked_request_body2.dart';
import '../models/app_delivery_calendar_open_request_body.dart';
import '../models/capacity_amount_request.dart';
import '../models/capacity_bucket_envelope.dart';
import '../models/capacity_calendar_envelope.dart';
import '../models/capacity_unit.dart';
import '../models/define_capacity_request.dart';
import '../models/effective_capacity_envelope.dart';
import '../models/get_app_delivery_calendar_options_response.dart';
import '../models/get_app_delivery_calendar_response.dart';
import '../models/open_delivery_slots_with_defaults_request.dart';
import '../models/post_app_delivery_calendar_open_default_response.dart';

part 'capacity_client.g.dart';

@RestApi()
abstract class CapacityClient {
  factory CapacityClient(Dio dio, {String? baseUrl}) = _CapacityClient;

  /// Available capacity for a bucket (internal app).
  ///
  /// Returns the capacity bucket for a given scope, date, time slot and unit.
  ///
  /// [municipalityId] - Municipality (coverage area) that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided. The municipality is the primary axis of capacity management.
  ///
  /// [nodeId] - Node that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided.
  ///
  /// [zoneId] - Zone that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided.
  ///
  /// [date] - Slot date (YYYY-MM-DD).
  ///
  /// [timeSlot] - Time slot within the same day, HH:MM-HH:MM.
  ///
  /// [unit] - Capacity unit of the bucket.
  @GET('/app/capacity/available')
  Future<CapacityBucketEnvelope> appGetAvailableCapacity({
    @Query('date') required DateTime date,
    @Query('time_slot') required String timeSlot,
    @Query('unit') required CapacityUnit unit,
    @Query('municipality_id') String? municipalityId,
    @Query('node_id') String? nodeId,
    @Query('zone_id') String? zoneId,
  });

  /// Capacity calendar for a date (internal app).
  ///
  /// Lists every capacity bucket of a day across all scopes, slots and units.
  ///
  /// [date] - Slot date (YYYY-MM-DD).
  ///
  /// [municipalityId] - Municipality (coverage area) that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided. The municipality is the primary axis of capacity management.
  @GET('/app/capacity/calendar')
  Future<CapacityCalendarEnvelope> appListCapacityCalendar({
    @Query('date') required DateTime date,
    @Query('municipality_id') String? municipalityId,
  });

  /// Effective capacity for a key (internal app).
  ///
  /// Returns the effective capacity for a scope/date/slot/unit: the explicit bucket when it exists, otherwise the default total from the configurable rules, or zero when neither applies. Never 404s.
  ///
  /// [municipalityId] - Municipality (coverage area) that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided. The municipality is the primary axis of capacity management.
  ///
  /// [nodeId] - Node that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided.
  ///
  /// [zoneId] - Zone that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided.
  ///
  /// [date] - Slot date (YYYY-MM-DD).
  ///
  /// [timeSlot] - Time slot within the same day, HH:MM-HH:MM.
  ///
  /// [unit] - Capacity unit of the bucket.
  @GET('/app/capacity/effective')
  Future<EffectiveCapacityEnvelope> appGetEffectiveCapacity({
    @Query('date') required DateTime date,
    @Query('time_slot') required String timeSlot,
    @Query('unit') required CapacityUnit unit,
    @Query('municipality_id') String? municipalityId,
    @Query('node_id') String? nodeId,
    @Query('zone_id') String? zoneId,
  });

  /// Available capacity for a bucket (channels).
  ///
  /// Read-only availability lookup used by client apps, web and call center.
  ///
  /// [municipalityId] - Municipality (coverage area) that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided. The municipality is the primary axis of capacity management.
  ///
  /// [nodeId] - Node that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided.
  ///
  /// [zoneId] - Zone that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided.
  ///
  /// [date] - Slot date (YYYY-MM-DD).
  ///
  /// [timeSlot] - Time slot within the same day, HH:MM-HH:MM.
  ///
  /// [unit] - Capacity unit of the bucket.
  @GET('/channels/capacity/available')
  Future<CapacityBucketEnvelope> channelsGetAvailableCapacity({
    @Query('date') required DateTime date,
    @Query('time_slot') required String timeSlot,
    @Query('unit') required CapacityUnit unit,
    @Query('municipality_id') String? municipalityId,
    @Query('node_id') String? nodeId,
    @Query('zone_id') String? zoneId,
  });

  /// Capacity calendar for a date (channels).
  ///
  /// Read-only calendar used by channels to offer dates and slots to the customer.
  ///
  /// [date] - Slot date (YYYY-MM-DD).
  ///
  /// [municipalityId] - Municipality (coverage area) that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided. The municipality is the primary axis of capacity management.
  @GET('/channels/capacity/calendar')
  Future<CapacityCalendarEnvelope> channelsListCapacityCalendar({
    @Query('date') required DateTime date,
    @Query('municipality_id') String? municipalityId,
  });

  /// Effective capacity for a key (channels).
  ///
  /// Read-only effective capacity used by client apps, web and call center to offer dates and slots. Returns the explicit bucket, the rule default, or zero when neither applies. Never 404s.
  ///
  /// [municipalityId] - Municipality (coverage area) that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided. The municipality is the primary axis of capacity management.
  ///
  /// [nodeId] - Node that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided.
  ///
  /// [zoneId] - Zone that owns the bucket. Exactly one of municipality_id/zone_id/node_id must be provided.
  ///
  /// [date] - Slot date (YYYY-MM-DD).
  ///
  /// [timeSlot] - Time slot within the same day, HH:MM-HH:MM.
  ///
  /// [unit] - Capacity unit of the bucket.
  @GET('/channels/capacity/effective')
  Future<EffectiveCapacityEnvelope> channelsGetEffectiveCapacity({
    @Query('date') required DateTime date,
    @Query('time_slot') required String timeSlot,
    @Query('unit') required CapacityUnit unit,
    @Query('municipality_id') String? municipalityId,
    @Query('node_id') String? nodeId,
    @Query('zone_id') String? zoneId,
  });

  /// Define a capacity bucket (integrations).
  ///
  /// Provisions a new bucket for a scope/date/slot/unit. Returns the resulting bucket.
  @POST('/integrations/capacity/buckets')
  Future<CapacityBucketEnvelope> integrationsDefineCapacity({
    @Body() required DefineCapacityRequest body,
  });

  /// Consume capacity from a bucket (integrations).
  ///
  /// Charges an amount to a bucket (e.g. when planning a shipment). Returns the updated bucket.
  @POST('/integrations/capacity/consume')
  Future<CapacityBucketEnvelope> integrationsConsumeCapacity({
    @Body() required CapacityAmountRequest body,
  });

  /// Release capacity from a bucket (integrations).
  ///
  /// Returns an amount to a bucket (e.g. on reschedule or failed delivery). Returns the updated bucket.
  @POST('/integrations/capacity/release')
  Future<CapacityBucketEnvelope> integrationsReleaseCapacity({
    @Body() required CapacityAmountRequest body,
  });

  /// Catalogs needed to activate delivery slots (municipalities, time slots, units, default windows).
  ///
  /// Admin y supervisor. Un solo request con los valores que aceptan POST /app/delivery-calendar/open y open-default.
  @GET('/app/delivery-calendar/options')
  Future<GetAppDeliveryCalendarOptionsResponse> getDeliveryCalendarOptions();

  /// Enable a date or date range with the default slots of the capacity rules (asynchronous).
  ///
  /// Admin y supervisor. Usa las ventanas por defecto de las reglas de cupo. Sin municipality_ids aplica a los municipios del catálogo completo; sin weekdays aplica a los siete días.
  @POST('/app/delivery-calendar/open-default')
  Future<PostAppDeliveryCalendarOpenDefaultResponse>
  openDeliverySlotsWithDefaults({
    @Body() required OpenDeliverySlotsWithDefaultsRequest body,
  });

  /// Delivery calendar — days with availability and blocked dates.
  ///
  /// Solo admin y supervisor. Mismo calendario de despacho del admin web. Rango máximo 62 días; por defecto 30 días desde hoy.
  ///
  /// [municipalityId] - Municipio (coverage). Sin él, el calendario global.
  @GET('/app/delivery-calendar')
  Future<GetAppDeliveryCalendarResponse> getDeliveryCalendar({
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
    @Query('municipality_id') String? municipalityId,
  });

  /// Block a delivery day (holiday, closure) for a municipality or globally
  @POST('/app/delivery-calendar/blocked')
  Future<AcceptedEnvelope> blockDeliveryDay({
    @Body() required AppDeliveryCalendarBlockedRequestBody body,
  });

  /// Remove the block of a delivery day
  @DELETE('/app/delivery-calendar/blocked')
  Future<AcceptedEnvelope> unblockDeliveryDay({
    @Body() required AppDeliveryCalendarBlockedRequestBody2 body,
  });

  /// Activate delivery slots for a date range, weekdays and windows (asynchronous)
  @POST('/app/delivery-calendar/open')
  Future<AcceptedEnvelope> openDeliverySlots({
    @Body() required AppDeliveryCalendarOpenRequestBody body,
  });
}
