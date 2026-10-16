// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_plans_plan_id_stops_request_body.g.dart';

@JsonSerializable()
class AppPlansPlanIdStopsRequestBody {
  const AppPlansPlanIdStopsRequestBody({required this.shipmentId});

  factory AppPlansPlanIdStopsRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppPlansPlanIdStopsRequestBodyFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;

  Map<String, Object?> toJson() => _$AppPlansPlanIdStopsRequestBodyToJson(this);
}
