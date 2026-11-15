// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stop_arrived_request_source.dart';

part 'stop_arrived_request.g.dart';

@JsonSerializable()
class StopArrivedRequest {
  const StopArrivedRequest({
    required this.occurredAt,
    required this.source,
    this.lat,
    this.lng,
    this.accuracyM,
  });

  factory StopArrivedRequest.fromJson(Map<String, Object?> json) =>
      _$StopArrivedRequestFromJson(json);

  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  final StopArrivedRequestSource source;
  final num? lat;
  final num? lng;
  @JsonKey(name: 'accuracy_m')
  final num? accuracyM;

  Map<String, Object?> toJson() => _$StopArrivedRequestToJson(this);
}
