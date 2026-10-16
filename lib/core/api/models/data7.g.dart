// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data7.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data7 _$Data7FromJson(Map<String, dynamic> json) => Data7(
  planId: json['plan_id'] as String,
  status: PlanStatus.fromJson(json['status'] as String),
  stops: (json['stops'] as List<dynamic>)
      .map((e) => StopEta.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Data7ToJson(Data7 instance) => <String, dynamic>{
  'plan_id': instance.planId,
  'status': instance.status,
  'stops': instance.stops,
};
