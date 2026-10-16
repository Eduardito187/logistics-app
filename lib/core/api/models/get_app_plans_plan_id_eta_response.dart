// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data7.dart';

part 'get_app_plans_plan_id_eta_response.g.dart';

@JsonSerializable()
class GetAppPlansPlanIdEtaResponse {
  const GetAppPlansPlanIdEtaResponse({required this.data});

  factory GetAppPlansPlanIdEtaResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppPlansPlanIdEtaResponseFromJson(json);

  final Data7 data;

  Map<String, Object?> toJson() => _$GetAppPlansPlanIdEtaResponseToJson(this);
}
