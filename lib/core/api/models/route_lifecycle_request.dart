// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'route_lifecycle_request.g.dart';

@JsonSerializable()
class RouteLifecycleRequest {
  const RouteLifecycleRequest({
    required this.occurredAt,
    this.routeDate,
    this.odometerKm,
    this.lat,
    this.lng,
  });

  factory RouteLifecycleRequest.fromJson(Map<String, Object?> json) =>
      _$RouteLifecycleRequestFromJson(json);

  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  @JsonKey(name: 'route_date')
  final DateTime? routeDate;
  @JsonKey(name: 'odometer_km')
  final num? odometerKm;
  final num? lat;
  final num? lng;

  Map<String, Object?> toJson() => _$RouteLifecycleRequestToJson(this);
}
