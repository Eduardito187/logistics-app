// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_plan_eta_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetPlanEtaData _$GetPlanEtaDataFromJson(Map<String, dynamic> json) =>
    GetPlanEtaData(
      planId: json['plan_id'] as String,
      status: PlanStatus.fromJson(json['status'] as String),
      stops: (json['stops'] as List<dynamic>)
          .map((e) => StopEta.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GetPlanEtaDataToJson(GetPlanEtaData instance) =>
    <String, dynamic>{
      'plan_id': instance.planId,
      'status': instance.status,
      'stops': instance.stops,
    };
