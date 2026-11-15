// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'carrier_trip_status.dart';

part 'carrier_trip_state.g.dart';

@JsonSerializable()
class CarrierTripState {
  const CarrierTripState({
    required this.tripId,
    required this.carrierId,
    required this.status,
    required this.scheduledAt,
    required this.startedAt,
    required this.closedAt,
    required this.cancelledAt,
    required this.shipmentsCount,
    this.reference,
  });

  factory CarrierTripState.fromJson(Map<String, Object?> json) =>
      _$CarrierTripStateFromJson(json);

  @JsonKey(name: 'trip_id')
  final String tripId;
  @JsonKey(name: 'carrier_id')
  final String carrierId;
  final String? reference;
  final CarrierTripStatus status;
  @JsonKey(name: 'scheduled_at')
  final DateTime scheduledAt;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;
  @JsonKey(name: 'shipments_count')
  final int shipmentsCount;

  Map<String, Object?> toJson() => _$CarrierTripStateToJson(this);
}
