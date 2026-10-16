// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coverage_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoverageRule _$CoverageRuleFromJson(Map<String, dynamic> json) => CoverageRule(
  nodeId: json['nodeId'] as String?,
  services: (json['services'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  baseMinutes: (json['baseMinutes'] as num).toInt(),
  productLimits: Map<String, int>.from(json['productLimits'] as Map),
  timeWindows: (json['timeWindows'] as List<dynamic>)
      .map((e) => TimeWindow.fromJson(e as Map<String, dynamic>))
      .toList(),
  serviceDays: (json['serviceDays'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$CoverageRuleToJson(CoverageRule instance) =>
    <String, dynamic>{
      'nodeId': instance.nodeId,
      'services': instance.services,
      'baseMinutes': instance.baseMinutes,
      'productLimits': instance.productLimits,
      'timeWindows': instance.timeWindows,
      'serviceDays': instance.serviceDays,
    };
