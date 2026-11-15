// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plan_status.dart';
import 'stop_eta.dart';

part 'get_plan_eta_data.g.dart';

@JsonSerializable()
class GetPlanEtaData {
  const GetPlanEtaData({
    required this.planId,
    required this.status,
    required this.stops,
  });

  factory GetPlanEtaData.fromJson(Map<String, Object?> json) =>
      _$GetPlanEtaDataFromJson(json);

  @JsonKey(name: 'plan_id')
  final String planId;
  final PlanStatus status;
  final List<StopEta> stops;

  Map<String, Object?> toJson() => _$GetPlanEtaDataToJson(this);
}
