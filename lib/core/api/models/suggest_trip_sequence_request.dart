// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'suggest_trip_sequence_request.g.dart';

@JsonSerializable()
class SuggestTripSequenceRequest {
  const SuggestTripSequenceRequest({
    required this.date,
    required this.vehicleId,
    required this.shipmentIds,
    this.departAt,
  });

  factory SuggestTripSequenceRequest.fromJson(Map<String, Object?> json) =>
      _$SuggestTripSequenceRequestFromJson(json);

  final DateTime date;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;

  /// Departure time. Defaults to the configured departure time of the day.
  @JsonKey(name: 'depart_at')
  final DateTime? departAt;
  @JsonKey(name: 'shipment_ids')
  final List<String> shipmentIds;

  Map<String, Object?> toJson() => _$SuggestTripSequenceRequestToJson(this);
}
