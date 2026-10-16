// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data6.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data6 _$Data6FromJson(Map<String, dynamic> json) => Data6(
  planId: json['plan_id'] as String,
  status: PlanStatus.fromJson(json['status'] as String),
  stops: (json['stops'] as List<dynamic>)
      .map((e) => StopEta.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$Data6ToJson(Data6 instance) => <String, dynamic>{
  'plan_id': instance.planId,
  'status': instance.status,
  'stops': instance.stops,
};
