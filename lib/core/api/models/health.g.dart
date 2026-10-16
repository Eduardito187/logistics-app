// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Health _$HealthFromJson(Map<String, dynamic> json) => Health(
  status: HealthStatus.fromJson(json['status'] as String),
  apiVersion: json['api_version'] as String,
  checks: Checks.fromJson(json['checks'] as Map<String, dynamic>),
);

Map<String, dynamic> _$HealthToJson(Health instance) => <String, dynamic>{
  'status': instance.status,
  'api_version': instance.apiVersion,
  'checks': instance.checks,
};
