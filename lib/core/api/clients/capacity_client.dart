// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/capacity_amount_request.dart';
import '../models/capacity_bucket_envelope.dart';
import '../models/capacity_calendar_envelope.dart';
import '../models/capacity_unit.dart';
import '../models/define_capacity_request.dart';
import '../models/effective_capacity_envelope.dart';

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
}
