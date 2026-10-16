// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/available_slot_collection.dart';
import '../models/get_channels_promises_delivery_response.dart';
import '../models/get_channels_promises_promise_id_response.dart';
import '../models/post_channels_delivery_slots_response.dart';
import '../models/post_channels_promises_promise_id_confirmation_response.dart';
import '../models/post_channels_promises_promise_id_reservation_response.dart';
import '../models/post_channels_promises_response.dart';
import '../models/post_channels_shipments_slot_reservation_response.dart';
import '../models/promise_offer_collection.dart';
import '../models/quote_promise_request.dart';
import '../models/reserve_delivery_slot_request.dart';
import '../models/reserve_municipality_slot_request.dart';
import '../models/reserve_promise_request.dart';

part 'promise_client.g.dart';

@RestApi()
abstract class PromiseClient {
  factory PromiseClient(Dio dio, {String? baseUrl}) = _PromiseClient;

  /// Quote a delivery promise for a shipment in a given slot.
  ///
  /// Leaves the promise in QUOTED state (no capacity reserved). Returns 202 with the quote echo; the promise id is exposed once the command returns it (see integration note in the controller).
  @POST('/channels/promises')
  Future<PostChannelsPromisesResponse> quotePromise({
    @Body() required QuotePromiseRequest body,
  });

  /// List delivery slots with available capacity for a zone and date.
  ///
  /// [date] - Date in Y-m-d format.
  @GET('/channels/promises/available-slots')
  Future<AvailableSlotCollection> listAvailableSlots({
    @Query('zone_id') required String zoneId,
    @Query('date') required DateTime date,
  });

  /// List deliverable dates and slots for a zone (coverage + capacity + corridor).
  ///
  /// Integrated delivery-promise calculation. For a coverage zone, returns the dates and time slots that can actually be promised, combining the zone's service days and base lead time (coverage), the free capacity per slot (capacity) and whether an operational corridor reaches the zone (network). Returns an empty collection when the zone is unknown/inactive or no corridor serves it.
  ///
  /// [from] - First day of the horizon in Y-m-d format. Defaults to today.
  ///
  /// [horizonDays] - How many days ahead to explore (the start day included).
  @GET('/channels/promises/offers')
  Future<PromiseOfferCollection> listDeliveryPromiseOffers({
    @Query('zone_id') required String zoneId,
    @Query('horizon_days') int? horizonDays = 14,
    @Query('from') DateTime? from,
  });

  /// Get a promise by id.
  ///
  /// [promiseId] - Promise identifier (UUID v7).
  @GET('/channels/promises/{promiseId}')
  Future<GetChannelsPromisesPromiseIdResponse> getPromise({
    @Path('promiseId') required String promiseId,
  });

  /// Confirm a reserved promise within its reservation window.
  ///
  /// [promiseId] - Promise identifier (UUID v7).
  @POST('/channels/promises/{promiseId}/confirmation')
  Future<PostChannelsPromisesPromiseIdConfirmationResponse> confirmPromise({
    @Path('promiseId') required String promiseId,
  });

  /// Reserve capacity for a quoted promise during a TTL window.
  ///
  /// [promiseId] - Promise identifier (UUID v7).
  @POST('/channels/promises/{promiseId}/reservation')
  Future<PostChannelsPromisesPromiseIdReservationResponse> reservePromise({
    @Path('promiseId') required String promiseId,
    @Body() required ReservePromiseRequest body,
  });

  /// Expire a promise reservation and release its capacity (channel abandon).
  ///
  /// [promiseId] - Promise identifier (UUID v7).
  @DELETE('/channels/promises/{promiseId}/reservation')
  Future<void> expireReservation({
    @Path('promiseId') required String promiseId,
  });

  /// Reserve a dispatch slot for an order (consume capacity and set the order's delivery slot).
  ///
  /// Atomic and idempotent: within one transaction it consumes one delivery from the zone capacity for the given date and window and sets that delivery slot on the shipment. Re-posting the exact same slot for the same order is a no-op (no extra capacity consumed). Responds 422 when capacity is exhausted, 404/422 when the order cannot take the slot.
  @POST('/channels/delivery-slots')
  Future<PostChannelsDeliverySlotsResponse> reserveDeliverySlot({
    @Body() required ReserveDeliverySlotRequest body,
  });

  /// List available delivery slots for a customer's municipality (K-05).
  ///
  /// Given a municipality, a coordinate (latitude + longitude) or a shipment, returns the dates and time slots available for dispatch in that municipality, honouring coverage, capacity, holidays and the horizon. The response carries no PII. Supports optional offset or cursor pagination (E-02): without pagination parameters the full collection is returned (with `meta.count`).
  ///
  /// [municipalityId] - Municipality id. One of municipality_id, latitude+longitude or shipment_id is required.
  ///
  /// [shipmentId] - Shipment id; its municipality is resolved. One destination vector is required.
  ///
  /// [latitude] - Latitude; must be sent together with longitude.
  ///
  /// [longitude] - Longitude; must be sent together with latitude.
  ///
  /// [fromDate] - First day of the horizon (Y-m-d). Defaults to today.
  ///
  /// [horizonDays] - How many days ahead to explore (the start day included).
  ///
  /// [page] - 1-based page number for offset pagination (E-02). When present, the response is sliced and a `meta` object is added. Omitting all pagination params returns the full collection unchanged.
  ///
  /// [perPage] - Page size for offset or cursor pagination (max 200).
  ///
  /// [cursor] - Opaque cursor for cursor pagination (E-02), taken from a previous response's `meta.next_cursor`. Preferred over `page` for large, growing collections.
  @GET('/channels/promises/delivery')
  Future<GetChannelsPromisesDeliveryResponse> listMunicipalityDeliveryPromise({
    @Query('horizon_days') int? horizonDays = 14,
    @Query('page') int? page = 1,
    @Query('per_page') int? perPage = 50,
    @Query('municipality_id') String? municipalityId,
    @Query('shipment_id') String? shipmentId,
    @Query('latitude') num? latitude,
    @Query('longitude') num? longitude,
    @Query('from_date') DateTime? fromDate,
    @Query('cursor') String? cursor,
  });

  /// Reserve a delivery slot for a shipment in its municipality (K-03).
  ///
  /// Atomically and idempotently resolves the shipment's municipality, validates the day, consumes the municipality capacity and fixes the slot on the shipment. Distinguishes the rejections the channel needs: slot already taken (409), day not dispatchable (422), shipment not found (404).
  @POST('/channels/shipments/slot-reservation')
  Future<PostChannelsShipmentsSlotReservationResponse> reserveMunicipalitySlot({
    @Body() required ReserveMunicipalitySlotRequest body,
  });
}
