// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reschedule_shipments_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RescheduleShipmentsResult _$RescheduleShipmentsResultFromJson(
  Map<String, dynamic> json,
) => RescheduleShipmentsResult(
  applied: json['applied'] as bool?,
  newDate: json['new_date'] == null
      ? null
      : DateTime.parse(json['new_date'] as String),
  windowStart: json['window_start'] as String?,
  windowEnd: json['window_end'] as String?,
  count: (json['count'] as num?)?.toInt(),
  skippedCount: (json['skipped_count'] as num?)?.toInt(),
  shipments: (json['shipments'] as List<dynamic>?)
      ?.map((e) => Shipments2.fromJson(e as Map<String, dynamic>))
      .toList(),
  skipped: (json['skipped'] as List<dynamic>?)
      ?.map((e) => Skipped.fromJson(e as Map<String, dynamic>))
      .toList(),
  failed: (json['failed'] as List<dynamic>?)
      ?.map((e) => Failed.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RescheduleShipmentsResultToJson(
  RescheduleShipmentsResult instance,
) => <String, dynamic>{
  'applied': instance.applied,
  'new_date': instance.newDate?.toIso8601String(),
  'window_start': instance.windowStart,
  'window_end': instance.windowEnd,
  'count': instance.count,
  'skipped_count': instance.skippedCount,
  'shipments': instance.shipments,
  'skipped': instance.skipped,
  'failed': instance.failed,
};
