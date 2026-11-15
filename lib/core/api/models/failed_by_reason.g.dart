// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'failed_by_reason.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FailedByReason _$FailedByReasonFromJson(Map<String, dynamic> json) =>
    FailedByReason(
      reason: json['reason'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$FailedByReasonToJson(FailedByReason instance) =>
    <String, dynamic>{'reason': instance.reason, 'count': instance.count};
