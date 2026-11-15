// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffActivity _$StaffActivityFromJson(Map<String, dynamic> json) =>
    StaffActivity(
      type: json['type'] == null
          ? null
          : StaffActivityType.fromJson(json['type'] as String),
      at: json['at'] == null ? null : DateTime.parse(json['at'] as String),
      title: json['title'] as String?,
      detail: json['detail'] as String?,
    );

Map<String, dynamic> _$StaffActivityToJson(StaffActivity instance) =>
    <String, dynamic>{
      'type': instance.type,
      'at': instance.at?.toIso8601String(),
      'title': instance.title,
      'detail': instance.detail,
    };
