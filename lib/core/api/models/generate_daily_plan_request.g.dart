// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generate_daily_plan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenerateDailyPlanRequest _$GenerateDailyPlanRequestFromJson(
  Map<String, dynamic> json,
) => GenerateDailyPlanRequest(
  planDate: DateTime.parse(json['plan_date'] as String),
  strategy: GenerateDailyPlanRequestStrategy.fromJson(
    json['strategy'] as String,
  ),
  params: json['params'] == null
      ? null
      : Params.fromJson(json['params'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GenerateDailyPlanRequestToJson(
  GenerateDailyPlanRequest instance,
) => <String, dynamic>{
  'plan_date': instance.planDate.toIso8601String(),
  'strategy': instance.strategy,
  'params': instance.params,
};
