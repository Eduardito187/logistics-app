// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_mode.dart';
import 'stop_time_window.dart';

part 'trip_candidate.g.dart';

@JsonSerializable()
class TripCandidate {
  const TripCandidate({
    required this.shipmentId,
    required this.unitsTotal,
    required this.fits,
    required this.suggested,
    this.orderReference,
    this.customerName,
    this.shortAddress,
    this.deliveryMode,
    this.lat,
    this.lng,
    this.distanceKmFromAnchor,
    this.timeWindow,
    this.weightKg,
    this.volumeM3,
    this.fitsReason,
    this.suggestedReason,
  });

  factory TripCandidate.fromJson(Map<String, Object?> json) =>
      _$TripCandidateFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  @JsonKey(name: 'order_reference')
  final String? orderReference;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'short_address')
  final String? shortAddress;
  @JsonKey(name: 'delivery_mode')
  final DeliveryMode? deliveryMode;
  @JsonKey(name: 'units_total')
  final int unitsTotal;
  final double? lat;
  final double? lng;

  /// Straight-line distance to the anchor. Null when the shipment has no location.
  @JsonKey(name: 'distance_km_from_anchor')
  final double? distanceKmFromAnchor;
  @JsonKey(name: 'time_window')
  final StopTimeWindow? timeWindow;
  @JsonKey(name: 'weight_kg')
  final double? weightKg;
  @JsonKey(name: 'volume_m3')
  final double? volumeM3;

  /// Has a location, fits the remaining weight and volume, and its time window is reachable.
  final bool fits;

  /// Human-readable reason (Spanish) when fits is false.
  @JsonKey(name: 'fits_reason')
  final String? fitsReason;

  /// Fits and is close to an already selected stop (or to the home base).
  final bool suggested;

  /// Human-readable reason (Spanish) when suggested is true.
  @JsonKey(name: 'suggested_reason')
  final String? suggestedReason;

  Map<String, Object?> toJson() => _$TripCandidateToJson(this);
}
