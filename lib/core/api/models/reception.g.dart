// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reception _$ReceptionFromJson(Map<String, dynamic> json) => Reception(
  status: json['status'] == null
      ? null
      : Status11.fromJson(json['status'] as String),
  expectedCount: (json['expected_count'] as num?)?.toInt(),
  receivedCount: (json['received_count'] as num?)?.toInt(),
  missingCount: (json['missing_count'] as num?)?.toInt(),
  surplusCount: (json['surplus_count'] as num?)?.toInt(),
  openedAt: json['opened_at'] == null
      ? null
      : DateTime.parse(json['opened_at'] as String),
  reconciledAt: json['reconciled_at'] == null
      ? null
      : DateTime.parse(json['reconciled_at'] as String),
);

Map<String, dynamic> _$ReceptionToJson(Reception instance) => <String, dynamic>{
  'status': instance.status,
  'expected_count': instance.expectedCount,
  'received_count': instance.receivedCount,
  'missing_count': instance.missingCount,
  'surplus_count': instance.surplusCount,
  'opened_at': instance.openedAt?.toIso8601String(),
  'reconciled_at': instance.reconciledAt?.toIso8601String(),
};
