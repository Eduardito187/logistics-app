// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'define_maintenance_plan_request_service_kind.dart';

part 'define_maintenance_plan_request.g.dart';

@JsonSerializable()
class DefineMaintenancePlanRequest {
  const DefineMaintenancePlanRequest({
    required this.vehicleId,
    required this.serviceKind,
    this.intervalKm,
    this.intervalDays,
  });

  factory DefineMaintenancePlanRequest.fromJson(Map<String, Object?> json) =>
      _$DefineMaintenancePlanRequestFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'service_kind')
  final DefineMaintenancePlanRequestServiceKind serviceKind;
  @JsonKey(name: 'interval_km')
  final int? intervalKm;
  @JsonKey(name: 'interval_days')
  final int? intervalDays;

  Map<String, Object?> toJson() => _$DefineMaintenancePlanRequestToJson(this);
}
